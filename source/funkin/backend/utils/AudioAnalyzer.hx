package funkin.backend.utils;

import lime.utils.ArrayBufferView.ArrayBufferIO;
import lime.utils.ArrayBuffer;

/**
 * An utility that analyze FlxSounds,
 * can be used to make waveform or real-time audio visualizer.
 */
final class AudioAnalyzer {
	/**
	 * Get bytes from an audio buffer with specified position and wordSize
	 * @param buffer The audio buffer to get byte from.
	 * @param position The specified position to get the byte from the audio buffer.
	 * @param wordSize How many bytes to get with to one byte (Usually it's bitsPerSample / 8 or bitsPerSample >> 3).
	 * @return Byte from the audio buffer with specified position.
	 */
	public static function getByte(buffer:ArrayBuffer, position:Int, wordSize:Int):Int {
		if (wordSize == 2) return inline ArrayBufferIO.getInt16(buffer, position);
		else if (wordSize == 3) {
			var b = inline ArrayBufferIO.getUint16(buffer, position) | (buffer.get(position + 2) << 16);
			if (b & 0x800000 != 0) return b - 0x1000000;
			else return b;
		}
		else if (wordSize == 4) return inline ArrayBufferIO.getInt32(buffer, position);
		else return inline ArrayBufferIO.getUint8(buffer, position) - 128;
	}
}
