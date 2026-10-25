// Explicit smoke test against the configured project. Creates an anonymous test
// identity and one private record, verifies access rules, then deletes both.
const fs = require('node:fs');
const path = require('node:path');
const { initializeApp, deleteApp } = require('firebase/app');
const { getAuth, signInAnonymously, deleteUser } = require('firebase/auth');
const { getFirestore, doc, setDoc, getDoc, deleteDoc, serverTimestamp, terminate, setLogLevel } = require('firebase/firestore');
async function main() {
  setLogLevel('silent');
  const source = fs.readFileSync(path.join(__dirname, '../../lib/firebase_options.dart'), 'utf8');
  const section = source.match(/static const FirebaseOptions web = FirebaseOptions\(([\s\S]*?)\);/);
  if (!section) throw new Error('Web Firebase options missing');
  const options = Object.fromEntries([...section[1].matchAll(/(\w+): '([^']+)'/g)].map(m => [m[1], m[2]]));
  const app = initializeApp(options, 'mikiko-live-smoke');
  const auth = getAuth(app);
  const db = getFirestore(app);
  let user;
  let own;
  try {
    user = (await signInAnonymously(auth)).user;
    own = doc(db, `users/${user.uid}/settings/connectionSmoke`);
    await setDoc(own, { payload: { purpose: 'backend-verification' }, mode: 'simulation', updatedAt: serverTimestamp() });
    if (!(await getDoc(own)).exists()) throw new Error('Private read failed');
    let denied = false;
    try { await getDoc(doc(db, 'users/some-other-user/settings/app')); }
    catch (e) { denied = e.code === 'permission-denied'; }
    if (!denied) throw new Error('Cross-user access was not denied');
    console.log('LIVE_FIREBASE_OK', JSON.stringify({ project: options.projectId, anonymousAuth: true, writeRead: true, otherUserDenied: true }));
  } finally {
    if (own) await deleteDoc(own);
    if (user) await deleteUser(user);
    await terminate(db);
    await deleteApp(app);
  }
}
main().catch(e => { console.error('LIVE_FIREBASE_FAILED', e.code || e.message); process.exitCode = 1; });
