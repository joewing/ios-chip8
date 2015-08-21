
#import <AudioToolbox/AudioToolbox.h>

#import "sound.h"

static CFStringRef beep_name = CFSTR("beep");
static SystemSoundID beep_sound;

static SystemSoundID LoadSound(CFStringRef name);

void InitializeSound() {
   AudioSessionInitialize(NULL, NULL, NULL, NULL);
   const UInt32 value = kAudioSessionCategory_UserInterfaceSoundEffects;
   AudioSessionSetProperty(kAudioSessionProperty_AudioCategory,
                          sizeof(value), &value);
   AudioSessionSetActive(true);
   beep_sound = LoadSound(beep_name);
}

void DestroySound() {
   AudioServicesDisposeSystemSoundID(beep_sound);
   AudioSessionSetActive(false);
}

void PlayBeep() {
   AudioServicesPlaySystemSound(beep_sound);
}

SystemSoundID LoadSound(CFStringRef name) {

   SystemSoundID sid;
   CFBundleRef bundle;
   CFURLRef url;

   bundle = CFBundleGetMainBundle();

   // Get a URL for the sound.
   url = CFBundleCopyResourceURL(bundle, name, CFSTR("wav"), NULL);

   OSStatus rc = AudioServicesCreateSystemSoundID(url, &sid);
   if(rc) {
      sid = 0;
   }

   CFRelease(url);

   return sid;

}

