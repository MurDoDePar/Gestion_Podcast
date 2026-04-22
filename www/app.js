// app.js

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

const subscribedList = document.getElementById('subscribed-list');
const newEpisodesList = document.getElementById('new-episodes-list');
const popularList = document.getElementById('popular-list');
const themeChipsContainer = document.getElementById('theme-chips');
const themePodcastList = document.getElementById('theme-podcast-list');

const themesList = [
  {
    cat: "Création & Arts", icon: "palette",
    desc: "Nourrir l'imaginaire et la créativité.",
    subs: [
      { name: "Architecture & Design", icon: "architecture", desc: "L'esthétique au service du fonctionnel." },
      { name: "Arts Visuels", icon: "brush", desc: "Peinture, sculpture et art contemporain." },
      { name: "Cinéma & Séries", icon: "movie", desc: "Analyse de films, séries et interviews de réalisateurs." },
      { name: "Littérature", icon: "menu_book", desc: "Classiques, polars ou fantasy." },
      { name: "Musique & Audio", icon: "music_note", desc: "Albums et histoires de genres (Jazz, Rap, Rock)." }
    ]
  },
  {
    cat: "Société & Enquêtes", icon: "policy",
    desc: "Le frisson du réel et la psychologie du mal.",
    subs: [
      { name: "Affaires Criminelles", icon: "gavel", desc: "Crimes, procès et psychologie du mal." },
      { name: "Stand-up & Comédie", icon: "sentiment_very_satisfied", desc: "Stand-up, sketchs et chroniques drôles." },
      { name: "Investigations", icon: "newspaper", desc: "Coulisses de l'info et enquêtes de terrain." },
      { name: "Espionnage & Histoire", icon: "visibility", desc: "Agents secrets, trahisons et grands événements historiques." },
      { name: "Mystères", icon: "help_outline", desc: "Affaires non résolues et énigmes persistantes." }
    ]
  },
  {
    cat: "Sciences & Avenir", icon: "science",
    desc: "Comprendre le fonctionnement de l'univers et du futur.",
    subs: [
      { name: "IA & Algorithmes", icon: "smart_toy", desc: "Intelligence artificielle, enjeux éthiques et futur numérique." },
      { name: "Espace & Astronomie", icon: "rocket_launch", desc: "Exploration spatiale et cosmologie." },
      { name: "Nature & Écologie", icon: "eco", desc: "Biodiversité, faune, flore et environnement." },
      { name: "Mathématiques", icon: "calculate", desc: "Logique, chiffres et beauté des maths." },
      { name: "Psychologie", icon: "psychology", desc: "Les secrets du cerveau humain." }
    ]
  },
  {
    cat: "Santé & Sports", icon: "sports",
    desc: "L'effort, la stratégie et le dépassement de soi.",
    subs: [
      { name: "Aventure Extrême", icon: "travel_explore", desc: "Exploits extrêmes et récits d'explorateurs." },
      { name: "Coaching Mental", icon: "stars", desc: "Développement personnel, mental et coaching sportif." },
      { name: "Sports Collectifs", icon: "groups", desc: "Football, basketball, rugby et sports d'équipe." },
      { name: "Sports Individuels", icon: "sports_mma", desc: "Athlétisme, natation, arts martiaux et sports solo." },
      { name: "Santé & Médecine", icon: "healing", desc: "Innovations médicales et fonctionnement du corps." }
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
    // Render theme chips when the 'Par thème' tab is selected
    if (tab.dataset.target === 'tab-theme') {
      renderThemeChips();
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
    renderSearchResults(data.results);
  } catch (err) {
    console.error(err);
    searchResults.innerHTML = '<p class="empty-state">Erreur de recherche.</p>';
  } finally {
    searchLoader.classList.add('hidden');
  }
}

function renderSearchResults(results) {
  searchResults.innerHTML = '';
  if (results.length === 0) {
    searchResults.innerHTML = '<p class="empty-state">Aucun résultat trouvé.</p>';
    return;
  }
  results.forEach(p => {
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
      return { title, audioUrl, pubDate, img, podcast: podcastInfo.collectionName };
    });

    if (settings.order === 'asc') episodes.reverse();

    renderEpisodesList(episodes, podcastEpisodesList);
  } catch(err) {
    console.error(err);
    podcastEpisodesList.innerHTML = '<p class="empty-state">Impossible de charger les épisodes.</p>';
  }
}

function updateSubscribeButton() {
  const isSub = subscribedPodcasts.find(p => p.collectionId === currentViewPodcast.collectionId);
  if (isSub) {
    btnSubscribe.textContent = "Se désabonner";
    btnSubscribe.style.background = 'var(--surface-color)';
    btnSubscribe.onclick = () => {
      subscribedPodcasts = subscribedPodcasts.filter(p => p.collectionId !== currentViewPodcast.collectionId);
      saveSubs();
      updateSubscribeButton();
    };
  } else {
    btnSubscribe.textContent = "S'abonner";
    btnSubscribe.style.background = 'var(--primary-gradient)';
    btnSubscribe.onclick = () => {
      subscribedPodcasts.push(currentViewPodcast);
      saveSubs();
      updateSubscribeButton();
    };
  }
}

function saveSubs() {
  localStorage.setItem('podstream_subs', JSON.stringify(subscribedPodcasts));
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
async function renderHome() {
  subscribedList.innerHTML = '';
  if (subscribedPodcasts.length === 0) {
    subscribedList.innerHTML = '<p class="empty-state">Aucun podcast. Ajoutez-en un !</p>';
    newEpisodesList.innerHTML = '';
    renderPopular();
    renderThemeChips();
    fetchThemePodcasts();
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
        allEps.sort((a,b) => b.pubDate - a.pubDate); // Always newest for "Nouveautés"
        renderEpisodesList(allEps, newEpisodesList);
     } catch(e){
        newEpisodesList.innerHTML = '';
     }
  }
  
  renderPopular();
  renderThemeChips();
  fetchThemePodcasts();
}

async function renderPopular() {
  if (!popularList) return;
  const langToCountry = {
      'fr': 'FR',
      'en': 'US',
      'es': 'ES',
      'de': 'DE'
  };
  let country = langToCountry[settings.lang] || 'FR'; 
  const url = `https://itunes.apple.com/search?media=podcast&term=podcast&limit=15&country=${country}`;
  
  try {
     const res = await fetchWithTimeout(url, { timeout: 8000 });
     const data = await res.json();
     popularList.innerHTML = '';
     
     data.results.forEach(p => {
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
  let country = langToCountry[settings.lang] || 'FR'; 
  
  const url = `https://itunes.apple.com/search?media=podcast&term=${encodeURIComponent(currentSelectedTheme)}&limit=15&country=${country}`;
  
  try {
     const res = await fetchWithTimeout(url, { timeout: 8000 });
     const data = await res.json();
     themePodcastList.innerHTML = '';
     if(data.results.length === 0) {
         themePodcastList.innerHTML = '<p class="empty-state">Aucun résultat trouvé.</p>';
         return;
     }
     data.results.forEach(p => {
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

audioEl.addEventListener('ended', () => {
    playIcon.textContent = 'play_arrow';
    if(currentEpisodePlaying) {
        listeningProgress[currentEpisodePlaying.audioUrl].completed = true;
        localStorage.setItem('podstream_progress', JSON.stringify(listeningProgress));
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

// Initial Render
renderHome();
