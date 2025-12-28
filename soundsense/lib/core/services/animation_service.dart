class AnimationService {
  // Map sound names to animation files
  static String getAnimationPath(String soundName) {
    final lower = soundName.toLowerCase();
    
    // Dog sounds
    if (lower.contains('dog') || lower.contains('bark') || lower.contains('growl')) {
      return 'assets/animations/dog.json';
    }
    
    // Car sounds
    if (lower.contains('car') || lower.contains('horn') || lower.contains('vehicle') || 
        lower.contains('truck') || lower.contains('traffic')) {
      return 'assets/animations/car.json';
    }

     if (lower.contains('bounce')) {
      return 'assets/animations/bloob.json';
    }
    
    // Music sounds
    if (lower.contains('music') || lower.contains('singing') || lower.contains('song') ||
        lower.contains('guitar') || lower.contains('piano') || lower.contains('drum')) {
      return 'assets/animations/music.json';
    }
    
    // Speech sounds
    if (lower.contains('speech') || lower.contains('talk') || lower.contains('voice') ||
        lower.contains('speak') || lower.contains('conversation')) {
      return 'assets/animations/speech.json';
    }
    
    // Alert/Emergency sounds
    if (lower.contains('siren') || lower.contains('alarm') || lower.contains('emergency') ||
        lower.contains('fire') || lower.contains('smoke') || lower.contains('scream') ||
        lower.contains('glass') || lower.contains('crash')) {
      return 'assets/animations/siren.json';
    }
    
    // Default - use alert animation
    return 'assets/animations/siren.json';
  }

  // Get emoji for sound
  static String getEmoji(String soundName) {
    final lower = soundName.toLowerCase();
    
    if (lower.contains('dog') || lower.contains('bark')) return '🐕';
    if (lower.contains('cat') || lower.contains('meow')) return '🐈';
    if (lower.contains('car') || lower.contains('horn')) return '🚗';
    if (lower.contains('music') || lower.contains('song')) return '🎵';
    if (lower.contains('speech') || lower.contains('talk')) return '🗣️';
    if (lower.contains('siren') || lower.contains('emergency')) return '🚨';
    if (lower.contains('alarm') || lower.contains('clock')) return '⏰';
    if (lower.contains('door') || lower.contains('bell')) return '🔔';
    if (lower.contains('baby') || lower.contains('cry')) return '👶';
    if (lower.contains('phone') || lower.contains('ring')) return '📞';
    if (lower.contains('bird') || lower.contains('chirp')) return '🐦';
    if (lower.contains('water') || lower.contains('rain')) return '💧';
    if (lower.contains('thunder') || lower.contains('storm')) return '⛈️';
    if (lower.contains('wind')) return '💨';
    if (lower.contains('fire')) return '🔥';
    if (lower.contains('glass') || lower.contains('break')) return '💥';
    if (lower.contains('knock')) return '🚪';
    if (lower.contains('clap') || lower.contains('applause')) return '👏';
    if (lower.contains('laugh')) return '😂';
    if (lower.contains('cough') || lower.contains('sneeze')) return '🤧';
    
    return '🔊';
  }

  // Get description for deaf users
  static String getDescription(String soundName, double confidence, String priority) {
    final emoji = getEmoji(soundName);
    final lower = soundName.toLowerCase();
    
    // Safety-critical descriptions
    if (priority == 'critical') {
      if (lower.contains('siren')) {
        return '$emoji Emergency vehicle nearby! Look around for flashing lights.';
      }
      if (lower.contains('car') || lower.contains('horn')) {
        return '$emoji Vehicle warning! Check your surroundings immediately.';
      }
      if (lower.contains('alarm') || lower.contains('fire') || lower.contains('smoke')) {
        return '$emoji Emergency alarm! Consider evacuating the area.';
      }
      if (lower.contains('scream') || lower.contains('shout')) {
        return '$emoji Someone may need help nearby!';
      }
      if (lower.contains('glass') || lower.contains('crash')) {
        return '$emoji Something broke nearby! Be careful of sharp objects.';
      }
      return '$emoji Critical sound detected! Stay alert.';
    }
    
    // Important descriptions
    if (priority == 'important') {
      if (lower.contains('dog') || lower.contains('bark')) {
        return '$emoji A dog is barking nearby. It might want attention or warning you.';
      }
      if (lower.contains('door') || lower.contains('bell') || lower.contains('knock')) {
        return '$emoji Someone might be at your door!';
      }
      if (lower.contains('baby') || lower.contains('cry')) {
        return '$emoji A baby is crying nearby and may need attention.';
      }
      if (lower.contains('phone') || lower.contains('ring')) {
        return '$emoji Your phone might be ringing!';
      }
      return '$emoji Important sound detected nearby.';
    }
    
    // Normal descriptions
    if (lower.contains('music')) {
      return '$emoji Music is playing nearby. Sounds like a nice tune!';
    }
    if (lower.contains('speech') || lower.contains('talk')) {
      return '$emoji People are talking nearby.';
    }
    if (lower.contains('bird')) {
      return '$emoji Birds are chirping. Nature sounds!';
    }
    if (lower.contains('rain') || lower.contains('water')) {
      return '$emoji Water or rain sounds detected.';
    }
    
    return '$emoji $soundName detected nearby.';
  }

  // Check if sound is critical (needs full screen alert)
  static bool isCriticalAlert(String soundName) {
    final lower = soundName.toLowerCase();
    return lower.contains('siren') || 
           lower.contains('alarm') ||
           lower.contains('fire') ||
           lower.contains('smoke') ||
           lower.contains('scream') ||
           lower.contains('horn') ||
           lower.contains('crash') ||
           lower.contains('glass break') ||
           lower.contains('gunshot') ||
           lower.contains('emergency');
  }
}