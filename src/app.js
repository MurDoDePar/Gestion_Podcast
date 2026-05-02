// app.js
import { initializeApp } from "firebase/app";
import { getAuth, signInWithPopup, GoogleAuthProvider, onAuthStateChanged, signOut } from "firebase/auth";
import { getFirestore, doc, setDoc, getDoc } from "firebase/firestore";
import { getDataConnect } from "firebase/data-connect";
import { connectorConfig, findUserByGoogleId, upsertUser, upsertPodcast, subscribeToPodcast, unsubscribeFromPodcast, updateSubscriptionOrder, upsertEpisode, updateListenHistory, getRecommendations, getMySubscriptions } from './dataconnect-generated/esm/index.esm.js';

const firebaseConfig = {
  apiKey: "AIzaSyAaKYdi1vEgQ7JZ3WOwwu4sFgTdRMlFtZw",
  authDomain: "podstream-a980a.firebaseapp.com",
  projectId: "podstream-a980a",
  storageBucket: "podstream-a980a.firebasestorage.app",
  messagingSenderId: "237480080047",
  appId: "1:237480080047:web:3b73f870a728bea5919a5a",
  measurementId: "G-4HBMBCQ1TL"
};

const app = initializeApp(firebaseConfig);
const auth = getAuth(app);
const db = getFirestore(app);
const dataConnect = getDataConnect(app, connectorConfig);

let currentUser = null;
let currentUserId = null;

function getPodcastUUID(collectionId) {
  return `00000000-0000-0000-0000-${String(collectionId).padStart(12, '0')}`;
}

function getEpisodeUUID(audioUrl) {
  let hash = 0;
  for (let i = 0; i < audioUrl.length; i++) hash = Math.imul(31, hash) + audioUrl.charCodeAt(i) | 0;
  const hex = Math.abs(hash).toString(16).padStart(8, '0');
  return `${hex}-0000-0000-0000-000000000000`;
}

// Registers Service Worker for PWA
if ('serviceWorker' in navigator) {
  navigator.serviceWorker.register('sw.js').catch(err => console.error('SW registration failed:', err));
}

// State
let subscribedPodcasts = JSON.parse(localStorage.getItem('podstream_subs')) || [];
let listeningProgress = JSON.parse(localStorage.getItem('podstream_progress')) || {}; // { episodeUrl: { time, duration, completed } }
let settings = JSON.parse(localStorage.getItem('podstream_settings')) || { lang: 'all', order: 'desc' };

// DOM Elements

const views = document.querySelectorAll('.view');
const navItems = document.querySelectorAll('.nav-item');
const searchInput = document.getElementById('search-input');
const searchResults = document.getElementById('search-results');
const searchLoader = document.getElementById('search-loader');
const userDisplayName = document.getElementById('user-display-name');

const subscribedList = document.getElementById('subscribed-list');
const newEpisodesList = document.getElementById('new-episodes-list');
const popularList = document.getElementById('popular-list');
const themeChipsContainer = document.getElementById('theme-chips');
const themePodcastList = document.getElementById('theme-podcast-list');

const themesList = [
  {
    cat: "Culture & Arts", icon: "palette",
    desc: "Découvrez le meilleur de la création culturelle et artistique.",
    subs: [
      { name: "Cinéma & Séries", icon: "movie", desc: "Analyse de films, séries et interviews." },
      { name: "Littérature & BD", icon: "menu_book", desc: "Classiques, romans et bandes dessinées." },
      { name: "Musique & Radio", icon: "music_note", desc: "Histoire musicale, genres et radio." },
      { name: "Histoire & Patrimoine", icon: "history_edu", desc: "Exploration du passé et du patrimoine." },
      { name: "Humour & Stand-up", icon: "sentiment_very_satisfied", desc: "Stand-up, comédie et divertissement." }
    ]
  },
  {
    cat: "Société & Récits", icon: "policy",
    desc: "Comprendre la société à travers ses histoires et ses débats.",
    subs: [
      { name: "Affaires Criminelles", icon: "gavel", desc: "Crimes, enquêtes et true crime." },
      { name: "Témoignages & Vie", icon: "record_voice_over", desc: "Parcours de vie et récits intimes." },
      { name: "Grandes Enquêtes", icon: "newspaper", desc: "Investigations et journalisme de fond." },
      { name: "Politique & Médias", icon: "campaign", desc: "Analyse politique et décryptage média." },
      { name: "Mystères & Paranormal", icon: "help_outline", desc: "Phénomènes inexpliqués et mystères." }
    ]
  },
  {
    cat: "Business & Tech", icon: "business_center",
    desc: "Les enjeux économiques et les innovations technologiques.",
    subs: [
      { name: "Entrepreneuriat", icon: "lightbulb", desc: "Création d'entreprise et leadership." },
      { name: "Finance & Économie", icon: "attach_money", desc: "Marchés, investissement et économie." },
      { name: "Intelligence Artificielle", icon: "smart_toy", desc: "IA, algorithmes et technologies futures." },
      { name: "Culture Numérique", icon: "devices", desc: "Impact du web et des réseaux sociaux." },
      { name: "Innovations & Futur", icon: "rocket_launch", desc: "Prospective et nouvelles tendances." }
    ]
  },
  {
    cat: "Savoirs & Vie", icon: "science",
    desc: "Apprendre, comprendre et mieux vivre au quotidien.",
    subs: [
      { name: "Psychologie & Mental", icon: "psychology", desc: "Fonctionnement de l'esprit et bien-être." },
      { name: "Santé & Nutrition", icon: "health_and_safety", desc: "Médecine, alimentation et forme." },
      { name: "Écologie & Nature", icon: "eco", desc: "Environnement, faune et flore." },
      { name: "Parentalité & Famille", icon: "family_restroom", desc: "Éducation, enfants et vie de famille." },
      { name: "Vulgarisation Scientifique", icon: "school", desc: "Sciences accessibles à tous." }
    ]
  },
  {
    cat: "Loisirs & Action", icon: "sports_esports",
    desc: "Le monde du sport, des passions et du divertissement.",
    subs: [
      { name: "Football & Collectifs", icon: "sports_soccer", desc: "Football, basket et sports d'équipe." },
      { name: "Sports Individuels", icon: "sports_martial_arts", desc: "Athlétisme, natation et sports solo." },
      { name: "Gastronomie & Vin", icon: "restaurant", desc: "Cuisine, chefs et œnologie." },
      { name: "Voyage & Aventure", icon: "flight", desc: "Exploration, carnets de voyage et évasion." },
      { name: "Jeux Vidéo & Geek", icon: "sports_esports", desc: "Gaming, pop culture et tech ludique." }
    ]
  }
];

// Sorting is done inside renderThemeChips() to guarantee order at render time

let currentGrandThemeIndex = 0;
let currentSelectedTheme = themesList[0].subs[0].name;

const podcastHeaderDiv = document.getElementById('podcast-header');
const podcastEpisodesList = document.getElementById('podcast-episodes-list');
const btnSubscribe = document.getElementById('btn-subscribe');

const playerContainer = document.getElementById('audio-player-container');
const audioEl = document.getElementById('main-audio');
const playBtn = document.getElementById('btn-play-pause');
const playIcon = document.getElementById('play-icon');
const progressBar = document.getElementById('progress-bar');
const progressContainer = document.getElementById('progress-container');

// View Management
function switchView(targetId) {
  views.forEach(v => v.classList.add('hidden'));
  document.getElementById(targetId).classList.remove('hidden');
  
  navItems.forEach(n => n.classList.remove('active'));
  const activeNav = document.querySelector(`.nav-item[data-target="${targetId}"]`);
  if (activeNav) activeNav.classList.add('active');
  
  if (targetId === 'view-home') renderHome();
}

// Top Tabs Management for view-home
const topTabs = document.querySelectorAll('.top-tab');
const tabContents = document.querySelectorAll('.tab-content');

topTabs.forEach(tab => {
  tab.addEventListener('click', () => {
    topTabs.forEach(t => t.classList.remove('active'));
    tabContents.forEach(c => c.classList.add('hidden'));
    tab.classList.add('active');
    document.getElementById(tab.dataset.target).classList.remove('hidden');
    // Render subscribed podcasts when 'Mes podcasts' tab is selected
    if (tab.dataset.target === 'tab-mes-podcasts') {
      renderSubscribedPodcasts();
    }
    
    // Render theme chips when the 'Par thème' tab is selected
    if (tab.dataset.target === 'tab-theme') {
      renderThemeChips();
    }
    
    // Render Popular podcasts when 'Populaires' tab is selected
    if (tab.dataset.target === 'tab-popular') {
      renderPopular();
    }

    // Render Affinities when 'Affinités' tab is selected
    if (tab.dataset.target === 'tab-affinities') {
      renderAffinities();
    }
  });
});

navItems.forEach(nav => {
  nav.addEventListener('click', () => switchView(nav.dataset.target));
});
document.getElementById('btn-back-podcast').addEventListener('click', () => switchView('view-home'));
document.getElementById('btn-back-settings').addEventListener('click', () => switchView('view-home'));
document.getElementById('btn-settings').addEventListener('click', () => switchView('view-settings'));
document.getElementById('btn-add-podcast').addEventListener('click', () => switchView('view-search'));

// Settings
const langSelect = document.getElementById('language-select');
const orderSelect = document.getElementById('order-select');
langSelect.value = settings.lang;
orderSelect.value = settings.order;

langSelect.addEventListener('change', (e) => { settings.lang = e.target.value; saveSettings(); });
orderSelect.addEventListener('change', (e) => { settings.order = e.target.value; saveSettings(); });

function saveSettings() {
  localStorage.setItem('podstream_settings', JSON.stringify(settings));
  if (currentUser) {
    setDoc(doc(db, "users", currentUser.uid), { settings: settings }, { merge: true }).catch(console.error);
  }
  renderHome();
}
async function fetchWithTimeout(resource, options = {}) {
  const { timeout = 5000 } = options;
  const controller = new AbortController();
  const id = setTimeout(() => controller.abort(), timeout);
  try {
    const response = await fetch(resource, { ...options, signal: controller.signal });
    clearTimeout(id);
    return response;
  } catch(err) {
    clearTimeout(id);
    throw err;
  }
}

async function fetchXmlCrossDomain(url) {
  const proxies = [
    `https://api.codetabs.com/v1/proxy?quest=${encodeURIComponent(url)}`,
    `https://api.allorigins.win/raw?url=${encodeURIComponent(url)}`,
    `https://corsproxy.io/?${encodeURIComponent(url)}`
  ];
  for (let proxy of proxies) {
    try {
      const res = await fetchWithTimeout(proxy, { timeout: 4000 });
      if (res.ok) {
        const text = await res.text();
        // codetabs might return empty body or HTML on redirect, so we must check if it's actual XML
        if (text && text.trim().length > 100 && text.includes('<')) {
          return text;
        }
      }
    } catch(e) {}
  }
  throw new Error("Unable to fetch feed");
}

function isPlayablePodcast(podcast) {
  if (!podcast.feedUrl) return false;
  const feedUrl = podcast.feedUrl.toLowerCase();
  // Filtrer les podcasts exclusifs qui ne fournissent pas de flux RSS public jouable
  const blockedDomains = ['radiofrance.fr', 'spotify.com'];
  if (blockedDomains.some(domain => feedUrl.includes(domain))) {
    return false;
  }
  return true;
}

async function filterByLanguage(results, expectedLang, limit = 15) {
    if (expectedLang === 'all') return results.slice(0, limit);
    
    // On prend un peu plus de résultats au cas où certains seraient filtrés
    const candidates = results.slice(0, 30);
    const valid = [];
    const batchSize = 5; // Requêtes en parallèle par lots
    
    for (let i = 0; i < candidates.length; i += batchSize) {
        const batch = candidates.slice(i, i + batchSize);
        const checks = await Promise.all(batch.map(async p => {
            try {
                const text = await fetchXmlCrossDomain(p.feedUrl);
                // On cherche la balise <language> dans le XML
                const match = text.match(/<language>\s*([^<\s]+)\s*<\/language>/i);
                if (match && match[1]) {
                    const lang = match[1].toLowerCase();
                    return lang.startsWith(expectedLang) ? p : null;
                }
                // Si la balise est absente, on le garde par précaution
                return p;
            } catch(e) {
                // Si le flux est injoignable, on le filtre
                return null;
            }
        }));
        
        valid.push(...checks.filter(p => p !== null));
        if (valid.length >= limit) break; // On arrête dès qu'on a le nombre requis
    }
    
    return valid.slice(0, limit);
}

// iTunes API Search
let searchTimeout;
searchInput.addEventListener('input', (e) => {
  clearTimeout(searchTimeout);
  const q = e.target.value.trim();
  if (q.length < 3) return;
  searchTimeout = setTimeout(() => performSearch(q), 500);
});

async function performSearch(query) {
  searchResults.innerHTML = '';
  searchLoader.classList.remove('hidden');
  try {
    let url = `https://itunes.apple.com/search?media=podcast&term=${encodeURIComponent(query)}&limit=15`;
    
    const langToCountry = {
      'fr': 'FR',
      'en': 'US',
      'es': 'ES',
      'de': 'DE'
    };

    if (settings.lang !== 'all' && langToCountry[settings.lang]) {
      url += `&country=${langToCountry[settings.lang]}`;
    }

    const res = await fetchWithTimeout(url, { timeout: 8000 });
    const data = await res.json();
    const validPlayable = data.results.filter(p => isPlayablePodcast(p));
    const finalResults = await filterByLanguage(validPlayable, settings.lang, 15);
    renderSearchResults(finalResults);
  } catch (err) {
    console.error(err);
    searchResults.innerHTML = '<p class="empty-state">Erreur de recherche.</p>';
  } finally {
    searchLoader.classList.add('hidden');
  }
}

function renderSearchResults(results) {
  searchResults.innerHTML = '';
  const validResults = results;
  if (validResults.length === 0) {
    searchResults.innerHTML = '<p class="empty-state">Aucun résultat jouable trouvé.</p>';
    return;
  }
  validResults.forEach(p => {
    const card = document.createElement('div');
    card.className = 'podcast-card';
    card.innerHTML = `
      <img src="${p.artworkUrl600 || p.artworkUrl100}" class="podcast-img" alt="Cover" loading="lazy">
      <h3>${p.collectionName}</h3>
      <p>${p.artistName}</p>
      <p class="genre-tag">${p.primaryGenreName || 'Podcast'}</p>
    `;
    card.addEventListener('click', () => openPodcastDetails(p));
    searchResults.appendChild(card);
  });
}

// Podcast Details & RSS Parsing
let currentViewPodcast = null;

async function openPodcastDetails(podcastInfo) {
  currentViewPodcast = podcastInfo;
  switchView('view-podcast');
  podcastHeaderDiv.innerHTML = `
    <img src="${podcastInfo.artworkUrl600 || podcastInfo.artworkUrl100}" alt="Cover">
    <h2>${podcastInfo.collectionName}</h2>
    <p>${podcastInfo.artistName}</p>
  `;
  podcastEpisodesList.innerHTML = '<div class="loader"></div>';
  
  updateSubscribeButton();
  
  // Fetch RSS Feed using CORS bypass
  try {
    const feedUrl = podcastInfo.feedUrl;
    if(!feedUrl) throw new Error("No feed URL");
    const text = await fetchXmlCrossDomain(feedUrl);
    
    // Parse XML
    const parser = new DOMParser();
    const xmlDoc = parser.parseFromString(text, "text/xml");
    const items = Array.from(xmlDoc.querySelectorAll('item'));
    
    // Convert to easier format
    let episodes = items.map(item => {
      let enclosure = item.querySelector('enclosure');
      let audioUrl = enclosure ? enclosure.getAttribute('url') : '';
      // Fallback if enclosure is missing but media:content might be present without standard namespace
      if (!audioUrl) {
        let media = item.getElementsByTagName('media:content')[0] || item.querySelector('[url$=".mp3"], [url$=".m4a"], [type^="audio/"]');
        if (media) audioUrl = media.getAttribute('url') || '';
      }
      let title = item.querySelector('title')?.textContent || 'Sans Titre';
      let pubDate = new Date(item.querySelector('pubDate')?.textContent).getTime() || 0;
      let img = item.getElementsByTagName('itunes:image')[0]?.getAttribute('href') || podcastInfo.artworkUrl100;
      let description = item.querySelector('description')?.textContent || '';
      return { title, audioUrl, pubDate, img, podcast: podcastInfo.collectionName, collectionId: podcastInfo.collectionId, description };
    });

    if (settings.order === 'asc') episodes.reverse();

    renderEpisodesList(episodes, podcastEpisodesList);
  } catch(err) {
    console.error(err);
    if(err.message === "No feed URL") {
      podcastEpisodesList.innerHTML = '<p class="empty-state" style="color:var(--danger); text-align:center; padding: 20px;">Ce podcast exclusif (Radio France, Spotify...) ne fournit pas de flux RSS public. Il est impossible de le lire ici.</p>';
    } else {
      podcastEpisodesList.innerHTML = '<p class="empty-state">Impossible de charger les épisodes.</p>';
    }
  }
}

function updateSubscribeButton() {
  const isSub = subscribedPodcasts.find(p => p.collectionId === currentViewPodcast.collectionId);
  const podId = getPodcastUUID(currentViewPodcast.collectionId);

  if (isSub) {
    btnSubscribe.textContent = "Se désabonner";
    btnSubscribe.style.background = 'var(--surface-color)';
    btnSubscribe.onclick = () => {
      subscribedPodcasts = subscribedPodcasts.filter(p => p.collectionId !== currentViewPodcast.collectionId);
      saveSubs();
      if(currentUserId) {
        unsubscribeFromPodcast(dataConnect, { userId: currentUserId, podcastId: podId }).catch(console.error);
      }
      updateSubscribeButton();
    };
  } else {
    btnSubscribe.textContent = "S'abonner";
    btnSubscribe.style.background = 'var(--primary-gradient)';
    btnSubscribe.onclick = () => {
      subscribedPodcasts.push(currentViewPodcast);
      saveSubs();
      if(currentUserId) {
        upsertPodcast(dataConnect, {
           id: podId,
           title: currentViewPodcast.collectionName || 'Unknown',
           feedUrl: currentViewPodcast.feedUrl || '',
           description: currentViewPodcast.description || '',
           imageUrl: currentViewPodcast.artworkUrl600 || currentViewPodcast.artworkUrl100 || '',
           author: currentViewPodcast.artistName || '',
           categories: currentViewPodcast.genres || [],
           createdAt: new Date().toISOString()
        }).then(() => {
           subscribeToPodcast(dataConnect, {
             userId: currentUserId,
             podcastId: podId,
             subscribedAt: new Date().toISOString(),
             listOrder: subscribedPodcasts.length - 1
           });
        }).catch(console.error);
      }
      updateSubscribeButton();
    };
  }
}

function saveSubs() {
  localStorage.setItem('podstream_subs', JSON.stringify(subscribedPodcasts));
  if (currentUser) {
    setDoc(doc(db, "users", currentUser.uid), { subscriptions: subscribedPodcasts }, { merge: true }).catch(console.error);
  }
}

function renderEpisodesList(episodes, container) {
  container.innerHTML = '';
  episodes.slice(0, 50).forEach(ep => {
    if (!ep.audioUrl) return;
    const progress = listeningProgress[ep.audioUrl] || { time: 0 };
    const isCompleted = progress.completed ? " (Terminé)" : "";
    
    const li = document.createElement('li');
    li.className = 'episode-item';
    li.innerHTML = `
      <img src="${ep.img}" class="episode-art" loading="lazy">
      <div class="episode-info">
        <h4>${ep.title}</h4>
        <p>${new Date(ep.pubDate).toLocaleDateString()} ${isCompleted}</p>
        ${progress.time > 0 && !progress.completed ? `<p style="color:var(--primary-color)">Reprise à ${Math.floor(progress.time/60)} min</p>` : ''}
      </div>
      <button class="icon-btn primary-icon play-ep-btn"><span class="material-symbols-rounded">play_arrow</span></button>
    `;
    li.querySelector('.play-ep-btn').addEventListener('click', () => playAudio(ep));
    container.appendChild(li);
  });
}

// Home Rendering
function renderSubscribedPodcasts() {
  subscribedList.innerHTML = '';
  if (subscribedPodcasts.length === 0) {
    subscribedList.innerHTML = '<p class="empty-state">Aucun podcast. Ajoutez-en un !</p>';
    return;
  }
  
  subscribedPodcasts.forEach(p => {
    const card = document.createElement('div');
    card.className = 'podcast-card';
    card.innerHTML = `
      <img src="${p.artworkUrl600 || p.artworkUrl100}" class="podcast-img" loading="lazy">
      <h3>${p.collectionName}</h3>
      <p class="genre-tag">${p.primaryGenreName || 'Podcast'}</p>
    `;
    card.addEventListener('click', () => openPodcastDetails(p));
    subscribedList.appendChild(card);
  });

  if (window.Sortable) {
    if (window.subscribedListSortable) {
       window.subscribedListSortable.destroy();
    }
    window.subscribedListSortable = new Sortable(subscribedList, {
      animation: 150,
      delay: 200,
      delayOnTouchOnly: true,
      onEnd: function (evt) {
        const oldIndex = evt.oldIndex;
        const newIndex = evt.newIndex;
        
        if (oldIndex !== newIndex) {
            const movedItem = subscribedPodcasts.splice(oldIndex, 1)[0];
            subscribedPodcasts.splice(newIndex, 0, movedItem);
            saveSubs();
            
            // Mettre à jour l'ordre dans SQL Connect
            if (currentUserId) {
                subscribedPodcasts.forEach((p, index) => {
                    updateSubscriptionOrder(dataConnect, {
                        userId: currentUserId,
                        podcastId: getPodcastUUID(p.collectionId),
                        listOrder: index
                    }).catch(console.error);
                });
            }
        }
      }
    });
  }
}

async function renderHome() {
  renderSubscribedPodcasts();
  
  if (subscribedPodcasts.length === 0) {
    newEpisodesList.innerHTML = '';
    renderPopular();
    renderThemeChips();
    fetchThemePodcasts();
    return;
  }
  
  // Minimal fetching for new episodes (just the first feed as demo to be fast)
  // In a real app we would Promise.all limit to fetch all feeds.
  if (subscribedPodcasts.length > 0) {
     newEpisodesList.innerHTML = '<div class="loader"></div>';
     try {
        const topPodcasts = subscribedPodcasts.slice(0, 3);
        let allEps = [];
        for(let p of topPodcasts) {
          try {
             const text = await fetchXmlCrossDomain(p.feedUrl);
             const xmlDoc = new DOMParser().parseFromString(text, "text/xml");
             const item = xmlDoc.querySelector('item');
             if(item) {
                let enc = item.querySelector('enclosure');
                if(enc) {
                  allEps.push({
                     audioUrl: enc.getAttribute('url'),
                     title: item.querySelector('title')?.textContent,
                     pubDate: new Date(item.querySelector('pubDate')?.textContent).getTime() || 0,
                     img: p.artworkUrl100,
                     podcast: p.collectionName
                  });
                }
             }
          } catch(e){}
        }
        
        if (settings.order === 'asc') {
          allEps.sort((a,b) => a.pubDate - b.pubDate); // Oldest first
        } else {
          allEps.sort((a,b) => b.pubDate - a.pubDate); // Newest first
        }
        
        renderEpisodesList(allEps, newEpisodesList);
     } catch(e){
        newEpisodesList.innerHTML = '';
     }
  }
  
  renderPopular();
  renderThemeChips();
  fetchThemePodcasts();
}

function shuffleArray(array) {
  for (let i = array.length - 1; i > 0; i--) {
    const j = Math.floor(Math.random() * (i + 1));
    [array[i], array[j]] = [array[j], array[i]];
  }
  return array;
}

async function renderPopular() {
  if (!popularList) return;
  popularList.innerHTML = '<div class="loader"></div>';
  const langToCountry = { 'fr': 'FR', 'en': 'US', 'es': 'ES', 'de': 'DE' };
  
  let url = `https://itunes.apple.com/search?media=podcast&term=podcast&limit=50`;
  if (settings.lang !== 'all' && langToCountry[settings.lang]) {
      url += `&country=${langToCountry[settings.lang]}`;
  }

  
  try {
     const res = await fetchWithTimeout(url, { timeout: 8000 });
     const data = await res.json();
     popularList.innerHTML = '';
     
     const validResults = data.results.filter(p => isPlayablePodcast(p));
     const randomResults = shuffleArray(validResults);
     
     const finalResults = await filterByLanguage(randomResults, settings.lang, 15);
     
     finalResults.forEach(p => {
        const card = document.createElement('div');
        card.className = 'podcast-card';
        card.innerHTML = `
          <img src="${p.artworkUrl600 || p.artworkUrl100}" class="podcast-img" loading="lazy">
          <h3>${p.collectionName}</h3>
          <p class="genre-tag">${p.primaryGenreName || 'Podcast'}</p>
        `;
        card.addEventListener('click', () => openPodcastDetails(p));
        popularList.appendChild(card);
     });
  } catch(e) {
     popularList.innerHTML = '<p class="empty-state">Impossible de charger les suggestions.</p>';
  }
}

async function renderAffinities() {
  const affinitiesList = document.getElementById('affinities-list');
  if (!affinitiesList) return;
  
  if (subscribedPodcasts.length === 0) {
    affinitiesList.innerHTML = '<p class="empty-state">Abonnez-vous à des podcasts pour voir les recommandations basées sur ce que les autres auditeurs écoutent !</p>';
    return;
  }
  
  if (!currentUserId) {
    affinitiesList.innerHTML = '<p class="empty-state">Connectez-vous pour voir les affinités.</p>';
    return;
  }
  
  affinitiesList.innerHTML = '<div class="loader"></div>';
  
  try {
    // Get recommendations for up to the first 5 subscribed podcasts
    const topSubs = subscribedPodcasts.slice(0, 5);
    const allRecommendations = [];
    
    for (let p of topSubs) {
      const podId = getPodcastUUID(p.collectionId);
      const res = await getRecommendations(dataConnect, { podcastId: podId });
      if (res.data && res.data.subscriptionTypes) {
        res.data.subscriptionTypes.forEach(st => {
          if (st.user && st.user.subscriptionTypes_on_user) {
            st.user.subscriptionTypes_on_user.forEach(uSub => {
              allRecommendations.push(uSub.podcast);
            });
          }
        });
      }
    }
    
    // Count frequencies and filter out already subscribed
    const recCounts = {};
    const subscribedIds = subscribedPodcasts.map(p => getPodcastUUID(p.collectionId));
    
    allRecommendations.forEach(p => {
      if (!subscribedIds.includes(p.id)) {
        if (!recCounts[p.id]) {
          recCounts[p.id] = { count: 0, podcast: p };
        }
        recCounts[p.id].count++;
      }
    });
    
    // Sort by count descending
    const sortedRecs = Object.values(recCounts)
      .sort((a, b) => b.count - a.count)
      .map(item => item.podcast);
      
    affinitiesList.innerHTML = '';
    
    if (sortedRecs.length === 0) {
      affinitiesList.innerHTML = '<p class="empty-state">Pas assez de données pour le moment. Découvrez plus de podcasts !</p>';
      return;
    }
    
    // Convert to format expected by openPodcastDetails
    sortedRecs.slice(0, 15).forEach(p => {
      const card = document.createElement('div');
      card.className = 'podcast-card';
      card.innerHTML = `
        <img src="${p.imageUrl}" class="podcast-img" loading="lazy">
        <h3>${p.title}</h3>
        <p class="genre-tag">${p.author || 'Recommandé'}</p>
      `;
      card.addEventListener('click', () => {
         openPodcastDetails({
            collectionId: p.id.split('-').pop(), // Approximation for UI consistency
            collectionName: p.title,
            artworkUrl600: p.imageUrl,
            artworkUrl100: p.imageUrl,
            feedUrl: p.feedUrl,
            artistName: p.author,
            genres: p.categories || []
         });
      });
      affinitiesList.appendChild(card);
    });
  } catch (e) {
    console.error("Affinities Error:", e);
    affinitiesList.innerHTML = '<p class="empty-state">Erreur lors du chargement des recommandations.</p>';
  }
}

const themeTabsContainer = document.getElementById('grand-theme-tabs');
const themeSubListContainer = document.getElementById('sub-theme-list');
const themeResultsTitle = document.getElementById('theme-results-title');

function renderThemeChips() {
  if(!themeTabsContainer || !themeSubListContainer) return;

  // Sort grand themes A→Z (fr-aware)
  themesList.sort((a, b) => a.cat.localeCompare(b.cat, 'fr', { sensitivity: 'base' }));
  // Sort sub-themes A→Z within each grand theme
  themesList.forEach(t => t.subs.sort((a, b) => a.name.localeCompare(b.name, 'fr', { sensitivity: 'base' })));

  // Render Grand Theme Tabs (with icon)
  themeTabsContainer.innerHTML = '';
  themesList.forEach((themeObj, index) => {
      const btn = document.createElement('button');
      btn.className = 'top-tab' + (index === currentGrandThemeIndex ? ' active' : '');
      btn.innerHTML = `<span class="material-symbols-rounded tab-icon">${themeObj.icon}</span>${themeObj.cat}`;
      btn.onclick = () => {
          if (currentGrandThemeIndex !== index) {
              currentGrandThemeIndex = index;
              // Auto-select first sub-theme of the new category
              currentSelectedTheme = themesList[index].subs[0].name;
          }
          renderThemeChips();
          if(themeResultsTitle) themeResultsTitle.classList.remove('hidden');
          fetchThemePodcasts();
      };
      themeTabsContainer.appendChild(btn);
  });

  // Render Sub-themes as horizontal tabs
  themeSubListContainer.innerHTML = '';
  const currentTheme = themesList[currentGrandThemeIndex];

  const subTabsRow = document.createElement('div');
  subTabsRow.className = 'sub-theme-tabs';

  currentTheme.subs.forEach(sub => {
      const btn = document.createElement('button');
      btn.className = 'sub-theme-tab' + (currentSelectedTheme === sub.name ? ' active' : '');
      btn.innerHTML = `<span class="material-symbols-rounded sub-tab-icon">${sub.icon}</span>${sub.name}`;
      btn.onclick = () => {
          currentSelectedTheme = sub.name;
          renderThemeChips();
          if(themeResultsTitle) themeResultsTitle.classList.remove('hidden');
          fetchThemePodcasts();
      };
      subTabsRow.appendChild(btn);
  });

  themeSubListContainer.appendChild(subTabsRow);
}

async function fetchThemePodcasts() {
  if(!themePodcastList) return;
  themePodcastList.innerHTML = '<div class="loader"></div>';
  const langToCountry = { 'fr': 'FR', 'en': 'US', 'es': 'ES', 'de': 'DE' };
  
  const themeTranslations = {
    // Culture & Arts
    "Cinéma & Séries": { en: "Movies TV", es: "Cine Series", de: "Filme Serien" },
    "Littérature & BD": { en: "Literature Comics", es: "Literatura Cómics", de: "Literatur Comics" },
    "Musique & Radio": { en: "Music Radio", es: "Música Radio", de: "Musik Radio" },
    "Histoire & Patrimoine": { en: "History Heritage", es: "Historia Patrimonio", de: "Geschichte Erbe" },
    "Humour & Stand-up": { en: "Comedy Stand-up", es: "Comedia Stand-up", de: "Comedy Stand-up" },
    
    // Société & Récits
    "Affaires Criminelles": { en: "True Crime", es: "Crimen Real", de: "Wahre Verbrechen" },
    "Témoignages & Vie": { en: "Testimonies Life", es: "Testimonios Vida", de: "Zeugnisse Leben" },
    "Grandes Enquêtes": { en: "Investigations", es: "Investigaciones", de: "Untersuchungen" },
    "Politique & Médias": { en: "Politics Media", es: "Política Medios", de: "Politik Medien" },
    "Mystères & Paranormal": { en: "Mysteries Paranormal", es: "Misterios Paranormal", de: "Mysterien Paranormal" },
    
    // Business & Tech
    "Entrepreneuriat": { en: "Entrepreneurship", es: "Emprendimiento", de: "Unternehmertum" },
    "Finance & Économie": { en: "Finance Economy", es: "Finanzas Economía", de: "Finanzen Wirtschaft" },
    "Intelligence Artificielle": { en: "Artificial Intelligence", es: "Inteligencia Artificial", de: "Künstliche Intelligenz" },
    "Culture Numérique": { en: "Digital Culture", es: "Cultura Digital", de: "Digitale Kultur" },
    "Innovations & Futur": { en: "Innovation Future", es: "Innovación Futuro", de: "Innovation Zukunft" },

    // Savoirs & Vie
    "Psychologie & Mental": { en: "Psychology Mental", es: "Psicología Mental", de: "Psychologie Mental" },
    "Santé & Nutrition": { en: "Health Nutrition", es: "Salud Nutrición", de: "Gesundheit Ernährung" },
    "Écologie & Nature": { en: "Ecology Nature", es: "Ecología Naturaleza", de: "Ökologie Natur" },
    "Parentalité & Famille": { en: "Parenting Family", es: "Crianza Familia", de: "Elternschaft Familie" },
    "Vulgarisation Scientifique": { en: "Science Popularization", es: "Divulgación Científica", de: "Wissenschaftspopularisierung" },

    // Loisirs & Action
    "Football & Collectifs": { en: "Team Sports", es: "Deportes de Equipo", de: "Mannschaftssportarten" },
    "Sports Individuels": { en: "Individual Sports", es: "Deportes Individuales", de: "Einzelsportarten" },
    "Gastronomie & Vin": { en: "Gastronomy Wine", es: "Gastronomía Vino", de: "Gastronomie Wein" },
    "Voyage & Aventure": { en: "Travel Adventure", es: "Viajes Aventura", de: "Reisen Abenteuer" },
    "Jeux Vidéo & Geek": { en: "Video Games Geek", es: "Videojuegos Geek", de: "Videospiele Geek" }
  };

  let searchTerm = currentSelectedTheme;
  if (settings.lang !== 'fr' && settings.lang !== 'all' && themeTranslations[currentSelectedTheme] && themeTranslations[currentSelectedTheme][settings.lang]) {
    searchTerm = themeTranslations[currentSelectedTheme][settings.lang];
  }

  let url = `https://itunes.apple.com/search?media=podcast&term=${encodeURIComponent(searchTerm)}&limit=50`;
  if (settings.lang !== 'all' && langToCountry[settings.lang]) {
      url += `&country=${langToCountry[settings.lang]}`;
  }
  
  try {
     const res = await fetchWithTimeout(url, { timeout: 8000 });
     const data = await res.json();
     themePodcastList.innerHTML = '';
     const validResults = data.results.filter(p => isPlayablePodcast(p));
     const randomResults = shuffleArray(validResults);
     
     const finalResults = await filterByLanguage(randomResults, settings.lang, 15);
     
     if(finalResults.length === 0) {
         themePodcastList.innerHTML = '<p class="empty-state">Aucun résultat jouable trouvé.</p>';
         return;
     }
     
     finalResults.forEach(p => {
        const card = document.createElement('div');
        card.className = 'podcast-card';
        card.innerHTML = `
          <img src="${p.artworkUrl600 || p.artworkUrl100}" class="podcast-img" loading="lazy">
          <h3>${p.collectionName}</h3>
          <p class="genre-tag">${p.primaryGenreName || 'Podcast'}</p>
        `;
        card.addEventListener('click', () => openPodcastDetails(p));
        themePodcastList.appendChild(card);
     });
  } catch(e) {
     themePodcastList.innerHTML = '<p class="empty-state">Impossible de charger ce thème.</p>';
  }
}

// Audio Player & Reprise Logic
let currentEpisodePlaying = null;

function playAudio(episode) {
  currentEpisodePlaying = episode;
  playerContainer.classList.remove('hidden');
  
  document.getElementById('player-art').src = episode.img;
  document.getElementById('player-title').textContent = episode.title;
  document.getElementById('player-podcast').textContent = episode.podcast;
  
  // Set Source and handle Resume (Reprise)
  if(audioEl.src !== episode.audioUrl) {
      audioEl.src = episode.audioUrl;
      const savedProg = listeningProgress[episode.audioUrl];
      if(savedProg && savedProg.time) {
          audioEl.currentTime = savedProg.time;
      }
  }
  
  audioEl.play();
  playIcon.textContent = 'pause';
}

playBtn.addEventListener('click', () => {
  if (audioEl.paused) {
    audioEl.play();
    playIcon.textContent = 'pause';
  } else {
    audioEl.pause();
    playIcon.textContent = 'play_arrow';
  }
});

document.getElementById('btn-rewind').addEventListener('click', () => { audioEl.currentTime = Math.max(0, audioEl.currentTime - 10); });
document.getElementById('btn-forward').addEventListener('click', () => { audioEl.currentTime += 10; });

audioEl.addEventListener('timeupdate', () => {
  if(!currentEpisodePlaying || !audioEl.duration) return;
  const t = audioEl.currentTime;
  const pct = (t / audioEl.duration) * 100;
  progressBar.style.width = pct + '%';
  
  // Save progress every 5 seconds
  if(Math.floor(t) % 5 === 0) {
      listeningProgress[currentEpisodePlaying.audioUrl] = {
         time: t,
         duration: audioEl.duration,
         completed: t >= (audioEl.duration - 10)
      };
      localStorage.setItem('podstream_progress', JSON.stringify(listeningProgress));
  }
});

function syncProgressToCloud() {
  if (currentUser) {
    setDoc(doc(db, "users", currentUser.uid), { progress: listeningProgress }, { merge: true }).catch(console.error);
    
    if (currentUserId && currentEpisodePlaying && currentEpisodePlaying.collectionId) {
        const podId = getPodcastUUID(currentEpisodePlaying.collectionId);
        const epId = getEpisodeUUID(currentEpisodePlaying.audioUrl);
        const prog = listeningProgress[currentEpisodePlaying.audioUrl];
        
        if (prog) {
            upsertEpisode(dataConnect, {
                id: epId,
                podcastId: podId,
                title: currentEpisodePlaying.title || 'Unknown',
                audioUrl: currentEpisodePlaying.audioUrl,
                duration: Math.floor(prog.duration || 0),
                description: currentEpisodePlaying.description ? currentEpisodePlaying.description.substring(0, 500) : '',
                imageUrl: currentEpisodePlaying.img || '',
                publishedAt: new Date(currentEpisodePlaying.pubDate || Date.now()).toISOString()
            }).then(() => {
                updateListenHistory(dataConnect, {
                    userId: currentUserId,
                    episodeId: epId,
                    progressSeconds: Math.floor(prog.time || 0),
                    finishedListening: !!prog.completed,
                    listenedAt: new Date().toISOString()
                }).catch(console.error);
            }).catch(console.error);
        }
    }
  }
}

audioEl.addEventListener('pause', syncProgressToCloud);

audioEl.addEventListener('ended', () => {
    playIcon.textContent = 'play_arrow';
    if(currentEpisodePlaying) {
        listeningProgress[currentEpisodePlaying.audioUrl].completed = true;
        localStorage.setItem('podstream_progress', JSON.stringify(listeningProgress));
        syncProgressToCloud();
    }
});

// Progress Bar Click
progressContainer.addEventListener('click', (e) => {
  if(!audioEl.duration) return;
  const rect = progressContainer.getBoundingClientRect();
  const x = e.clientX - rect.left;
  const pct = x / rect.width;
  audioEl.currentTime = pct * audioEl.duration;
});

// Firebase Auth & UI Logic
const viewLogin = document.getElementById('view-login');
const btnGoogleLogin = document.getElementById('btn-google-login');
const btnLogout = document.getElementById('btn-logout');

onAuthStateChanged(auth, async (user) => {
  if (user) {
    currentUser = user;
    viewLogin.classList.add('hidden');
    
    if (userDisplayName) {
      userDisplayName.textContent = user.displayName || user.email || 'Utilisateur';
      userDisplayName.style.display = 'flex';
    }
    
    // Configure Data Connect User
    try {
      const res = await findUserByGoogleId(dataConnect, { googleId: user.uid });
      if (res.data.users.length > 0) {
        currentUserId = res.data.users[0].id;
      } else {
        currentUserId = crypto.randomUUID();
        await upsertUser(dataConnect, {
          id: currentUserId,
          googleId: user.uid,
          displayName: user.displayName || 'Utilisateur',
          email: user.email || '',
          photoUrl: user.photoURL || '',
          createdAt: new Date().toISOString()
        });
      }
    } catch(e) {
      console.error("DataConnect User Error:", e);
    }
    
    // Fetch subscriptions from Data Connect regardless of Firestore doc
    if (currentUserId) {
      try {
        const subRes = await getMySubscriptions(dataConnect, { userId: currentUserId }, { fetchPolicy: 'network-only' });
        if (subRes.data && subRes.data.subscriptionTypes && subRes.data.subscriptionTypes.length > 0) {
          const subs = subRes.data.subscriptionTypes.map(st => {
             return {
                collectionId: parseInt(st.podcast.id.split('-').pop(), 10) || Date.now(),
                collectionName: st.podcast.title,
                feedUrl: st.podcast.feedUrl,
                artworkUrl100: st.podcast.imageUrl,
                artworkUrl600: st.podcast.imageUrl,
                artistName: st.podcast.author,
                genres: st.podcast.categories || [],
                _listOrder: st.listOrder
             };
          });
          
          subs.sort((a, b) => (a._listOrder || 0) - (b._listOrder || 0));
          subs.forEach(s => delete s._listOrder);
          
          subscribedPodcasts = subs;
          localStorage.setItem('podstream_subs', JSON.stringify(subscribedPodcasts));
        } else {
          // If Data Connect is empty, try to migrate from Firestore
          const docSnap = await getDoc(doc(db, "users", user.uid));
          if (docSnap.exists()) {
            const data = docSnap.data();
            if (data.subscriptions && data.subscriptions.length > 0) {
              subscribedPodcasts = data.subscriptions;
              localStorage.setItem('podstream_subs', JSON.stringify(subscribedPodcasts));
              
              subscribedPodcasts.forEach((p, index) => {
                const podId = getPodcastUUID(p.collectionId);
                upsertPodcast(dataConnect, {
                  id: podId,
                  title: p.collectionName || 'Unknown',
                  feedUrl: p.feedUrl || '',
                  description: p.description || '',
                  imageUrl: p.artworkUrl600 || p.artworkUrl100 || '',
                  author: p.artistName || '',
                  categories: p.genres || [],
                  createdAt: new Date().toISOString()
                }).then(() => {
                  subscribeToPodcast(dataConnect, {
                    userId: currentUserId,
                    podcastId: podId,
                    subscribedAt: new Date().toISOString(),
                    listOrder: index
                  });
                }).catch(console.error);
              });
            }
          }
        }
      } catch(e) {
        console.error("DataConnect Subscriptions Error:", e);
      }
    }

    // Fetch progress and settings from firestore
    try {
      const docSnap = await getDoc(doc(db, "users", user.uid));
      if (docSnap.exists()) {
        const data = docSnap.data();
        if (data.progress) {
          listeningProgress = data.progress;
          localStorage.setItem('podstream_progress', JSON.stringify(listeningProgress));
        }
        if (data.settings) {
          settings = data.settings;
          localStorage.setItem('podstream_settings', JSON.stringify(settings));
          document.getElementById('language-select').value = settings.lang || 'all';
          document.getElementById('order-select').value = settings.order || 'desc';
        }
      }
    } catch(e) { console.error("Error fetching data", e); }
    
    switchView('view-home');
  } else {
    currentUser = null;
    viewLogin.classList.remove('hidden');
    if (userDisplayName) {
      userDisplayName.style.display = 'none';
      userDisplayName.textContent = '';
    }
  }
});

btnGoogleLogin.addEventListener('click', () => {
  const provider = new GoogleAuthProvider();
  // Utilisation de popup pour le Web (PWA)
  signInWithPopup(auth, provider).catch(error => {
    console.error("Auth Error", error);
    alert("Erreur de connexion : " + error.message);
  });
});

btnLogout.addEventListener('click', () => {
  signOut(auth).then(() => {
    subscribedPodcasts = [];
    listeningProgress = {};
    localStorage.clear();
    location.reload();
  });
});

