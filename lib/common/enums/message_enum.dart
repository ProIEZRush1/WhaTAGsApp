enum MessageEnum {
  text('text'),
  image('image'),
  audio('audio'),
  voice('voice'),
  video('video'),
  gif('gif'),
  vcard('vcard'),
  sticker('sticker'),
  document('document'),
  location('location');

  const MessageEnum(this.type);

  final String type;
}

// Using an extension
// Enhanced enums

extension ConvertMessage on String {
  MessageEnum toEnum() {
    switch (this) {
      case 'text':
        return MessageEnum.text;
      case 'image':
        return MessageEnum.image;
      case 'audio':
        return MessageEnum.audio;
      case 'voice':
        return MessageEnum.voice;
      case 'video':
        return MessageEnum.video;
      case 'document':
        return MessageEnum.document;
      case 'gif':
        return MessageEnum.gif;
      case 'vcard':
        return MessageEnum.vcard;
      case 'location':
        return MessageEnum.location;
      case 'sticker':
        return MessageEnum.sticker;
      default:
        return MessageEnum.text;
    }
  }
}
