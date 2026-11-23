# Privacy

**The camera stays on your phone.** With the hand blade or "See my room" on, the page uses the phone's rear camera. A hand-tracking library (Google MediaPipe) runs in your browser to find your index fingertip. The picture is processed on the phone and is never sent, recorded or saved.

**Motion sensors.** The page reads the phone's orientation to follow your head. Those readings are used only to draw the view and are not saved.

**LiDAR (iPhone app only).** With "LiDAR distance" on, the app reads the phone's LiDAR sensor and rear camera to measure how far away things are and to find your hand. The picture and the depth readings are processed on the phone and are never sent, recorded or saved; only the distances shown on screen are passed to the page, and they are not kept.

**What is saved.** After each round a few numbers are saved in this browser's local storage (`fruitVRRounds`, at most 200 rounds): the time, blade mode, fruit thrown and sliced, swipes and how many cut, swipe speed, how often the hand was lost, how many times a second it was found, how far off-centre the blade passed, the frame rate, the screen size and the camera's name as the phone reports it. The learned aim correction is saved too (`fruitVRBias`, two angles). They stay in that browser. "Clear" on the setup page deletes them. "Copy results" puts them on your clipboard only when you press it.

**Third parties your browser contacts.** Loading the page fetches three.js from cdnjs, the hand-tracking library from jsDelivr and its model from Google's storage; those services see your IP address like any website you visit. The page itself has no analytics, cookies or accounts.

**Not a medical test, no warranty.** See `DISCLAIMER.md`.
