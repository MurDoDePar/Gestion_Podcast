#!/usr/bin/env node

/**
 * Script de Test "Stress Social" pour l'onglet Affinité - PodStream
 * 
 * Ce script :
 * 1. Initialise des abonnements factices dans la collection 'subscriptions' pour simuler plusieurs utilisateurs.
 * 2. Simule l'algorithme d'affinité pour l'utilisateur principal de test.
 * 3. Valide que les recommandations de podcasts sont exactes et triées par score.
 * 4. Nettoie la base Firestore.
 * 
 * Usage :
 *   $env:GOOGLE_APPLICATION_CREDENTIALS="C:\Users\domin\.gemini\antigravity-ide\scratch\adc.json"
 *   $env:GCLOUD_PROJECT="podstream-a980a"
 *   node test_social_stress.js
 */

const admin = require('firebase-admin');

// Initialisation de Firebase Admin
admin.initializeApp();
const db = admin.firestore();

// Identifiants des utilisateurs de test
const CURRENT_USER = 'user_test_123';
const PEER_USER_1 = 'peer_user_abc';
const PEER_USER_2 = 'peer_user_xyz';
const PEER_USER_3 = 'peer_user_qsd'; // Utilisateur sans affinité

const MOCK_DATA = [
  // Abonnements de l'utilisateur actuel (A et B)
  { userId: CURRENT_USER, feedUrl: 'https://feed-a.xml', collectionName: 'Podcast A', orderIndex: 0 },
  { userId: CURRENT_USER, feedUrl: 'https://feed-b.xml', collectionName: 'Podcast B', orderIndex: 1 },

  // Abonnements du Pair 1 (Partage A, écoute aussi C et D)
  { userId: PEER_USER_1, feedUrl: 'https://feed-a.xml', collectionName: 'Podcast A', orderIndex: 0 },
  { userId: PEER_USER_1, feedUrl: 'https://feed-c.xml', collectionName: 'Podcast C', orderIndex: 1 },
  { userId: PEER_USER_1, feedUrl: 'https://feed-d.xml', collectionName: 'Podcast D', orderIndex: 2 },

  // Abonnements du Pair 2 (Partage B, écoute aussi E)
  { userId: PEER_USER_2, feedUrl: 'https://feed-b.xml', collectionName: 'Podcast B', orderIndex: 0 },
  { userId: PEER_USER_2, feedUrl: 'https://feed-e.xml', collectionName: 'Podcast E', orderIndex: 1 },

  // Abonnements du Pair 3 (Aucun podcast en commun)
  { userId: PEER_USER_3, feedUrl: 'https://feed-f.xml', collectionName: 'Podcast F', orderIndex: 0 },
  { userId: PEER_USER_3, feedUrl: 'https://feed-g.xml', collectionName: 'Podcast G', orderIndex: 1 },
];

async function seedData() {
  console.log('🌱 Phase 1 : Insertion des abonnements factices dans Firestore...');
  const batch = db.batch();
  
  MOCK_DATA.forEach(sub => {
    const docRef = db.collection('subscriptions').doc();
    batch.set(docRef, {
      ...sub,
      subscribedAt: admin.firestore.FieldValue.serverTimestamp()
    });
  });
  
  await batch.commit();
  console.log('   [OK] Abonnements insérés avec succès.');
}

async function simulateAffinityAlgorithm() {
  console.log('\n🧠 Phase 2 : Simulation de la logique d\'affinité (getAffinityPodcasts)...');

  // 1. Définir les abonnements de l'utilisateur de test
  const currentUserFeeds = ['https://feed-a.xml', 'https://feed-b.xml'];
  console.log(`   - Podcasts de l'utilisateur actuel (${CURRENT_USER}) :`, currentUserFeeds);

  // 2. Trouver les utilisateurs ayant au moins un podcast en commun
  // Firestore 'whereIn'
  const peerOverlapCounts = {}; // peerUserId -> overlap count
  
  const peerSnapshot = await db.collection('subscriptions')
    .where('feedUrl', 'in', currentUserFeeds)
    .get();

  peerSnapshot.docs.forEach(doc => {
    const data = doc.data();
    const peerId = data.userId;
    if (peerId && peerId !== CURRENT_USER) {
      peerOverlapCounts[peerId] = (peerOverlapCounts[peerId] || 0) + 1;
    }
  });

  console.log('   - Scores d\'affinité des utilisateurs pairs (nombre d\'overlaps) :', peerOverlapCounts);

  if (Object.keys(peerOverlapCounts).length === 0) {
    console.log('   ❌ Aucun utilisateur pair trouvé.');
    return;
  }

  // Trier les pairs par score décroissant et prendre le top 10
  const sortedPeers = Object.entries(peerOverlapCounts)
    .sort((a, b) => b[1] - a[1])
    .map(entry => entry[0]);

  console.log('   - Top des utilisateurs pairs classés :', sortedPeers);

  // 3. Récupérer les abonnements de ces pairs
  const recommendedPodcasts = {};
  const recommendedScores = {}; // feedUrl -> score cumulé

  for (const peerId of sortedPeers) {
    const peerWeight = peerOverlapCounts[peerId];
    const peerSubsSnapshot = await db.collection('subscriptions')
      .where('userId', '==', peerId)
      .get();

    peerSubsSnapshot.docs.forEach(doc => {
      const data = doc.data();
      const feedUrl = data.feedUrl;
      
      // Exclure les abonnements que le CURRENT_USER possède déjà
      if (currentUserFeeds.includes(feedUrl)) return;

      if (!recommendedPodcasts[feedUrl]) {
        recommendedPodcasts[feedUrl] = {
          collectionName: data.collectionName,
          artistName: data.artistName || 'Inconnu',
          artworkUrl: data.artworkUrl600 || '',
          feedUrl: feedUrl
        };
      }

      // Le score cumulé correspond à la somme des poids d'affinité des pairs qui l'écoutent
      recommendedScores[feedUrl] = (recommendedScores[feedUrl] || 0) + peerWeight;
    });
  }

  // 4. Classer les recommandations par score d'affinité
  const recommendations = Object.entries(recommendedScores)
    .sort((a, b) => b[1] - a[1])
    .map(entry => ({
      ...recommendedPodcasts[entry[0]],
      score: entry[1]
    }));

  console.log('\n📊 Recommandations générées par le Test :');
  recommendations.forEach((rec, idx) => {
    console.log(`   #${idx + 1} : "${rec.collectionName}" | Flux : ${rec.feedUrl} | Score d'Affinité : ${rec.score}`);
  });

  // Validation
  const recUrls = recommendations.map(r => r.feedUrl);
  const expectedUrls = ['https://feed-c.xml', 'https://feed-d.xml', 'https://feed-e.xml'];
  
  const allFound = expectedUrls.every(url => recUrls.includes(url));
  const excluded = !recUrls.includes('https://feed-a.xml') && !recUrls.includes('https://feed-b.xml');
  const excludedPeer3 = !recUrls.includes('https://feed-f.xml') && !recUrls.includes('https://feed-g.xml');

  if (allFound && excluded && excludedPeer3) {
    console.log('\n✅ SUCCÈS : L\'algorithme a parfaitement calculé l\'affinité sociale !');
  } else {
    console.error('\n❌ ÉCHEC : Erreur dans le calcul ou le filtrage des affinités.');
  }
}

async function cleanupData() {
  console.log('\n🧹 Phase 3 : Nettoyage des abonnements de test dans Firestore...');
  const testUsers = [CURRENT_USER, PEER_USER_1, PEER_USER_2, PEER_USER_3];
  
  const snapshot = await db.collection('subscriptions')
    .where('userId', 'in', testUsers)
    .get();

  const batch = db.batch();
  snapshot.docs.forEach(doc => batch.delete(doc.ref));
  await batch.commit();
  console.log(`   [OK] ${snapshot.size} abonnements temporaires supprimés.`);
}

async function main() {
  try {
    await seedData();
    await simulateAffinityAlgorithm();
  } catch (err) {
    console.error('❌ Erreur générale :', err);
  } finally {
    await cleanupData();
    console.log('👋 Fin du test.');
  }
}

main().catch(console.error);
