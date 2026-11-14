class_name PlaceholderSounds
extends RefCounted
## Makes simple sounds in code so the game needs no audio files yet.
## Replace with real sounds in Phase 6.

const MIX_RATE := 22050


## A short burst of fading white noise: good enough for a gunshot.
static func noise_burst(seconds: float, volume: float = 0.6) -> AudioStreamWAV:
	var count := int(seconds * MIX_RATE)
	var bytes := PackedByteArray()
	bytes.resize(count * 2)
	for i in count:
		var fade := 1.0 - float(i) / float(count)
		var sample := randf_range(-1.0, 1.0) * fade * fade * volume
		bytes.encode_s16(i * 2, int(sample * 32767.0))
	return _wav(bytes)


## A plain beep: good enough for terminals and alarms.
static func tone(frequency: float, seconds: float, volume: float = 0.4) -> AudioStreamWAV:
	var count := int(seconds * MIX_RATE)
	var bytes := PackedByteArray()
	bytes.resize(count * 2)
	for i in count:
		var fade := 1.0 - float(i) / float(count)
		var sample := sin(TAU * frequency * float(i) / MIX_RATE) * fade * volume
		bytes.encode_s16(i * 2, int(sample * 32767.0))
	return _wav(bytes)


static func _wav(bytes: PackedByteArray) -> AudioStreamWAV:
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = MIX_RATE
	wav.data = bytes
	return wav
