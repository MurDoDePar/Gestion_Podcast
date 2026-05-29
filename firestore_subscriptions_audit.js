#!/usr/bin/env node

/**
 * Script d'Audit de Cohérence Firestore / SQLite - PodStream
 * 
 * Ce script compare la collection Firestore 'subscriptions' avec l'état SQLite.
 * Il peut lire directement 'podstream.db' si le CLI sqlite3 est installé et que le fichier est présent localement,
 * ou lire un fichier d'export JSON nommé 'my_podcasts_export.json'.
 * 
 * Usage :
 *   $env:GOOGLE_APPLICATION_CREDENTIALS="C:\Users\domin\.gemini\antigravity-ide\scratch\adc.json"
 *   $env:GCLOUD_PROJECT="podstream-a980a"
 *   node firestore_subscriptions_audit.js <userId> [chemin_vers_db_ou_json]
 */

const admin = require('firebase-admin');
const fs = require('fs');
const { execSync } = require('child_process');

const args = process.argv.slice(2);
const userId = args[0];
const dataPath = args[1] || 'podstream.db';

if (!userId) {
  console.error("❌ Erreur : Veuillez spécifier l'userId Firebase en argument.");
  console.error("Usage : node firestore_subscriptions_audit.js <userId> [chemin_vers_db_ou_json]");
  process.exit(1);
}

// Initialisation de Firebase Admin
admin.initializeApp();
const db = admin.firestore();

// Charger les données SQLite
let sqlitePodcasts = [];

if (dataPath.endsWith('.json')) {
  if (!fs.existsSync(dataPath)) {
    console.error(`❌ Erreur : Le fichier JSON '${dataPath}' n'existe pas.`);
    process.exit(1);
  }
  try {
    sqlitePodcasts = JSON.parse(fs.readFileSync(dataPath, 'utf8'));
    console.log(`✅ Lecture des données SQLite depuis l'export JSON '${dataPath}' (${sqlitePodcasts.length} podcasts).`);
  } catch (err) {
    console.error("❌ Erreur de lecture du JSON :", err.message);
    process.exit(1);
  }
} else if (dataPath.endsWith('.db') || dataPath === 'podstream.db') {
  if (!fs.existsSync(dataPath)) {
    console.warn(`⚠️ Warning : '${dataPath}' non trouvé.`);
    console.warn(`💡 Conseil : Exportez d'abord la table locale depuis adb ou placez 'podstream.db' ici.`);
    console.warn(`   Ou fournissez un export JSON en argument : node firestore_subscriptions_audit.js <userId> export.json`);
    process.exit(1);
  }
  try {
    // Essayer de lire la base SQLite via le CLI de sqlite3
    console.log(`🔍 Extraction de la table 'my_podcasts' depuis '${dataPath}'...`);
    const query = `
      SELECT json_group_array(
        json_object(
          'feedUrl', feedUrl,
          'collectionName', collectionName,
          'sortOrder', sortOrder
        )
      ) 
      FROM my_podcasts;
    `;
    // Remplacement des sauts de ligne pour exécution saine sous cmd/powershell
    const command = `sqlite3 "${dataPath}" "${query.replace(/\s+/g, ' ')}"`;
    const result = execSync(command).toString().trim();
    sqlitePodcasts = JSON.parse(result);
    console.log(`✅ Extraction réussie : ${sqlitePodcasts.length} podcasts trouvés.`);
  } catch (err) {
    console.error("❌ Impossible d'extraire les données SQLite. Assurez-vous que sqlite3 CLI est installé.");
    console.error("Détail de l'erreur :", err.message);
    process.exit(1);
  }
}

async function runAudit() {
  console.log('\n================================================================');
  console.log(`             AUDIT FIRESTORE vs SQLITE - USER: ${userId}        `);
  console.log('================================================================');

  // 1. Convertir les données SQLite en Map (feedUrl -> sortOrder)
  const sqliteMap = new Map();
  sqlitePodcasts.forEach(p => {
    sqliteMap.set(p.feedUrl, {
      collectionName: p.collectionName || p.title || 'Sans titre',
      sortOrder: p.sortOrder
    });
  });

  // 2. Requêter Firestore pour l'utilisateur
  console.log(`📡 Requêtage des abonnements Firestore pour ${userId}...`);
  const snapshot = await db.collection('subscriptions')
    .where('userId', '==', userId)
    .get();

  const firestoreMap = new Map();
  snapshot.docs.forEach(doc => {
    const data = doc.data();
    if (data.feedUrl) {
      firestoreMap.set(data.feedUrl, {
        collectionName: data.collectionName || 'Sans titre',
        orderIndex: data.orderIndex !== undefined ? data.orderIndex : -1,
        docId: doc.id
      });
    }
  });

  console.log(`📊 Statistiques : SQLite = ${sqliteMap.size} abonnements | Firestore = ${firestoreMap.size} abonnements\n`);

  // 3. Comparaison des ensembles
  let inconsistencies = 0;

  // Abonnements dans SQLite mais absents dans Firestore
  for (const [feedUrl, localData] of sqliteMap.entries()) {
    if (!firestoreMap.has(feedUrl)) {
      console.warn(`❌ [NON SYNCHRONISÉ] Absent sur Firestore : "${localData.collectionName}"`);
      console.warn(`   Flux : ${feedUrl}\n`);
      inconsistencies++;
    } else {
      // Comparaison de l'ordre de tri
      const remoteData = firestoreMap.get(feedUrl);
      if (localData.sortOrder !== remoteData.orderIndex) {
        console.warn(`⚠️ [TRI DÉSALIGNÉ] "${localData.collectionName}" :`);
        console.warn(`   SQLite sortOrder = ${localData.sortOrder} | Firestore orderIndex = ${remoteData.orderIndex}\n`);
        inconsistencies++;
      }
    }
  }

  // Abonnements dans Firestore mais absents dans SQLite
  for (const [feedUrl, remoteData] of firestoreMap.entries()) {
    if (!sqliteMap.has(feedUrl)) {
      console.warn(`❌ [ABSENT EN LOCAL] Présent uniquement sur Firestore : "${remoteData.collectionName}"`);
      console.warn(`   Document Firestore ID : ${remoteData.docId}`);
      console.warn(`   Flux : ${feedUrl}\n`);
      inconsistencies++;
    }
  }

  if (inconsistencies === 0) {
    console.log("✅ FÉLICITATIONS : SQLite (SSOT) et Firestore sont parfaitement alignés et synchrones !");
  } else {
    console.error(`❌ ÉCHEC : L'audit a détecté ${inconsistencies} incohérence(s) de données.`);
  }
  console.log('================================================================\n');
}

runAudit().catch(err => {
  console.error("❌ Erreur lors de l'exécution de l'audit :", err);
});
