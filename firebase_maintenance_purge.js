#!/usr/bin/env node

/**
 * Script de Maintenance Firebase - Purge Sécurisée et Diagnostic (Phase n+2)
 * 
 * Usage :
 *   1. Lancement en simulation (Dry Run) :
 *      $env:GOOGLE_APPLICATION_CREDENTIALS="C:\Users\domin\.gemini\antigravity-ide\scratch\adc.json"
 *      $env:GCLOUD_PROJECT="podstream-a980a"
 *      node firebase_maintenance_purge.js
 * 
 *   2. Lancement réel destructif (Purge active) :
 *      $env:GOOGLE_APPLICATION_CREDENTIALS="C:\Users\domin\.gemini\antigravity-ide\scratch\adc.json"
 *      $env:GCLOUD_PROJECT="podstream-a980a"
 *      node firebase_maintenance_purge.js --execute
 */

const admin = require('firebase-admin');

// 1. Détermination des arguments de la ligne de commande
const args = process.argv.slice(2);
const isDryRun = args.includes('--execute') ? false : true; // Par défaut, dry-run actif

// 2. Initialisation de Firebase Admin
if (process.env.FIRESTORE_EMULATOR_HOST) {
  console.log(`[EMULATOR] Connexion active sur ${process.env.FIRESTORE_EMULATOR_HOST}`);
  admin.initializeApp({
    projectId: 'demo-podcast' // requis par l'émulateur
  });
} else {
  console.log('[PROD] Connexion au projet Firebase actif...');
  try {
    admin.initializeApp();
  } catch (error) {
    console.error('❌ Erreur d\'initialisation. Veuillez exécuter "gcloud auth application-default login" ou définir GOOGLE_APPLICATION_CREDENTIALS.');
    process.exit(1);
  }
}

const db = admin.firestore();
const activeProjectId = admin.app().options.projectId || db.projectId;

console.log('================================================================');
console.log('       SCRIPT DE PURGE ET MAINTENANCE FIRESTORE - PODSTREAM     ');
console.log('================================================================');
console.log(`PROJET CIBLE     : ${activeProjectId}`);
console.log(`MODE D'EXÉCUTION : ${isDryRun ? 'DRY-RUN (SIMULATION)' : 'ENVIRONNEMENT RÉEL (SUPPRESSION ACTIVE)'}`);
if (isDryRun) {
  console.log('💡 Note: Aucun document ne sera réellement supprimé. Utilisez --execute pour valider.');
}
console.log('================================================================\n');

// 3. Whitelist de sécurité (Collections critiques protégées de toute suppression)
const PROTECTED_COLLECTIONS = [
  'users',            // Historique utilisateur principal
  'system',           // Configuration et versions supportées
  'subscriptions',    // Abonnements actifs (requis pour l'onglet Affinité)
  'episodes',         // Index global des épisodes
  'User',             // Conservé par sécurité
  'Podcast'           // Conservé par sécurité pour l'affinité
];

// Collections obsolètes à purger en Phase n+2 (Firestore uniquement)
const OBSOLETE_COLLECTIONS = [
  'raw_rss_cache',
  'old_episode_status',
  'AppCache',
  'SubscriptionType',
  'ListenHistory',
  'Episode'
];

// 4. Fonction de purge par collection
async function purgeCollection(collectionName) {
  if (PROTECTED_COLLECTIONS.includes(collectionName)) {
    console.warn(`[ATTENTION] La collection "${collectionName}" fait partie de la whitelist de protection. Purge refusée.`);
    return;
  }

  console.log(`[DÉBUT] Analyse de la collection : "${collectionName}"`);
  
  const collectionRef = db.collection(collectionName);
  const batchSize = 500; // Limite stricte de Firestore par lot
  let totalProcessed = 0;
  
  try {
    // Boucle de pagination pour récupérer les documents
    while (true) {
      // Récupérer un lot de documents
      const snapshot = await collectionRef.limit(batchSize).get();
      
      if (snapshot.empty) {
        break;
      }

      console.log(`   - Lot de ${snapshot.size} documents trouvé...`);
      
      if (!isDryRun) {
        const batch = db.batch();
        snapshot.docs.forEach((doc) => {
          batch.delete(doc.ref);
        });
        await batch.commit();
        totalProcessed += snapshot.size;
        console.log(`   [OK] ${snapshot.size} documents supprimés de "${collectionName}". Total: ${totalProcessed}`);
      } else {
        // En mode dry-run, on simule et on s'arrête pour éviter de boucler indéfiniment
        totalProcessed += snapshot.size;
        console.log(`   [DRY-RUN] Simule la suppression de ${snapshot.size} documents.`);
        break; // Arrêt en dry-run pour éviter la boucle infinie
      }
    }
    
    console.log(`[FIN] Collection "${collectionName}" traitée. Total impacté : ${totalProcessed} documents.\n`);
  } catch (error) {
    console.error(`❌ Erreur lors du traitement de la collection "${collectionName}" :`, error);
  }
}

// 5. Exécution séquentielle
async function run() {
  for (const collection of OBSOLETE_COLLECTIONS) {
    await purgeCollection(collection);
  }
  console.log('✅ Traitement de maintenance terminé.');
}

run();
