#!/usr/bin/env node

/**
 * Script de Maintenance Firebase - Purge Sécurisée des Collections Obsolètes (Phase n+2)
 * 
 * Usage :
 *   1. Lancement en simulation (Émulateur local) :
 *      $env:FIRESTORE_EMULATOR_HOST="localhost:8080"
 *      node firebase_maintenance_purge.js --dry-run
 * 
 *   2. Lancement réel sur la base de Production (nécessite l'auth active ou GOOGLE_APPLICATION_CREDENTIALS) :
 *      node firebase_maintenance_purge.js --execute
 */

const admin = require('firebase-admin');

// 1. Détermination des arguments de la ligne de commande
const args = process.argv.slice(2);
const isDryRun = args.includes('--execute') ? false : true; // Par défaut, dry-run actif

console.log('================================================================');
console.log('       SCRIPT DE PURGE ET MAINTENANCE FIRESTORE - PODSTREAM     ');
console.log('================================================================');
console.log(`MODE D\'EXÉCUTION : ${isDryRun ? 'DRY-RUN (SIMULATION)' : 'ENVIRONNEMENT RÉEL (SUPPRESSION ACTIVE)'}`);
if (isDryRun) {
  console.log('💡 Note: Aucun document ne sera réellement supprimé. Utilisez --execute pour valider.');
}
console.log('================================================================\n');

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

// 3. Whitelist de sécurité (Collections critiques protégées)
const PROTECTED_COLLECTIONS = [
  'users',
  'system',
  'subscriptions',
  'archive_subscriptions'
];

// Collections obsolètes à purger en Phase n+2
const OBSOLETE_COLLECTIONS = [
  'raw_rss_cache',
  'old_episode_status'
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
        // Si la taille est inférieure à la pagination, on a tout scanné, sinon on break pour éviter la boucle infinie en Dry Run
        if (snapshot.size < batchSize) {
          break;
        } else {
          console.log(`   [DRY-RUN] Plus de documents sont disponibles. La simulation s'arrête ici pour ce lot.`);
          break;
        }
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
