const { before, beforeEach, after, test } = require('node:test');
const fs = require('node:fs');
const path = require('node:path');
const { initializeTestEnvironment, assertFails, assertSucceeds } = require('@firebase/rules-unit-testing');
const { doc, setDoc, getDoc, deleteDoc, serverTimestamp } = require('firebase/firestore');
let env;
before(async () => {
  env = await initializeTestEnvironment({ projectId: 'demo-mikiko-smart-farming', firestore: {
    host: '127.0.0.1', port: 8085,
    rules: fs.readFileSync(path.join(__dirname, '..', 'firestore.rules'), 'utf8'),
  }});
});
beforeEach(async () => { await env.clearFirestore(); });
after(async () => { await env.cleanup(); });
const record = () => ({ payload: { id: 'farm-a', name: 'Kebun Mikiko' }, mode: 'simulation', updatedAt: serverTimestamp() });
test('authenticated owner can create, read, update and delete own farm', async () => {
  const db = env.authenticatedContext('owner-a').firestore();
  const ref = doc(db, 'users/owner-a/farms/farm-a');
  await assertSucceeds(setDoc(ref, record()));
  await assertSucceeds(getDoc(ref));
  await assertSucceeds(setDoc(ref, { ...record(), payload: { name: 'Blok B' } }));
  await assertSucceeds(deleteDoc(ref));
});
test('another user cannot read or write owner data', async () => {
  const db = env.authenticatedContext('owner-b').firestore();
  const ref = doc(db, 'users/owner-a/farms/farm-a');
  await assertFails(setDoc(ref, record()));
  await assertFails(getDoc(ref));
});
test('signed-out client cannot access app data', async () => {
  const ref = doc(env.unauthenticatedContext().firestore(), 'users/owner-a/farms/farm-a');
  await assertFails(setDoc(ref, record()));
  await assertFails(getDoc(ref));
});
test('client cannot claim simulated data came from physical hardware', async () => {
  const ref = doc(env.authenticatedContext('owner-a').firestore(), 'users/owner-a/soilMeasurements/one');
  await assertFails(setDoc(ref, { ...record(), mode: 'hardware' }));
});
test('device telemetry and unknown collections remain denied', async () => {
  const db = env.authenticatedContext('owner-a').firestore();
  await assertFails(setDoc(doc(db, 'devices/node-01'), record()));
  await assertFails(setDoc(doc(db, 'users/owner-a/admin/config'), record()));
});
test('record requires payload map and server timestamp', async () => {
  const ref = doc(env.authenticatedContext('owner-a').firestore(), 'users/owner-a/tasks/task-1');
  await assertFails(setDoc(ref, { ...record(), payload: 'invalid' }));
  await assertFails(setDoc(ref, { ...record(), updatedAt: new Date(0) }));
  await assertFails(setDoc(ref, { ...record(), admin: true }));
});
