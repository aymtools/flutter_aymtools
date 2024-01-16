import 'dart:core';

///字符   	          意义
// \a 007 0x0007	  响铃(BEL)
// \b 008 0x0008	退格(BS) ，将当前位置移到前一列
// \t 009	0x009   水平制表(HT) （跳到下一个TAB位置）
// \n 010 0x00A	  换行(LF) ，将当前位置移到下一行开头
// \v 011 0x00B	  垂直制表(VT)
// \f 012 0x00C	  换页(FF)，将当前位置移到下页开头
// \r 013 0x00D	  回车(CR) ，将当前位置移到本行开头
const String _escapeCharacter = r'\abtnvfr';

extension StringControlCharExt on String {
  String removeAllControlCharacter() {
    // 将字符串中所有的控制符移除
    List<int> charCodes = [];
    for (int i = 0; i < length; i++) {
      var char = codeUnitAt(i);
      if (char <= 0x001F || char == 0x007F) {
        // 移除所有的控制字符
      } else {
        charCodes.add(char);
      }
    }
    return String.fromCharCodes(charCodes);
  }

  String escapeControlCharacter() {
    // 转移常用的字符 非常用的跳过
    List<int> charCodes = [];
    for (int i = 0; i < length; i++) {
      var char = codeUnitAt(i);
      if (char <= 0x001F || char == 0x007F) {
        switch (char) {
          case 0x0007: // \a
            charCodes.add(_escapeCharacter.codeUnitAt(0));
            charCodes.add(_escapeCharacter.codeUnitAt(1));
            break;
          case 0x0008: //\b
            charCodes.add(_escapeCharacter.codeUnitAt(0));
            charCodes.add(_escapeCharacter.codeUnitAt(2));
            break;
          case 0x0009: // \t
            charCodes.add(_escapeCharacter.codeUnitAt(0));
            charCodes.add(_escapeCharacter.codeUnitAt(3));
            break;
          case 0x000A: // \n
            charCodes.add(_escapeCharacter.codeUnitAt(0));
            charCodes.add(_escapeCharacter.codeUnitAt(4));
            break;
          case 0x000B: // \v
            charCodes.add(_escapeCharacter.codeUnitAt(0));
            charCodes.add(_escapeCharacter.codeUnitAt(5));
            break;
          case 0x000C: // \f
            charCodes.add(_escapeCharacter.codeUnitAt(0));
            charCodes.add(_escapeCharacter.codeUnitAt(6));
            break;
          case 0x000D: // \r
            charCodes.add(_escapeCharacter.codeUnitAt(0));
            charCodes.add(_escapeCharacter.codeUnitAt(7));
            break;
        }

        // 非常用的跳过
      } else {
        charCodes.add(char);
      }
    }
    return String.fromCharCodes(charCodes);
  }
}
