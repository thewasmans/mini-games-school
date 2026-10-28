extends Node
## Petits sons synthétisés au lancement (aucun fichier audio nécessaire).

const RATE := 22050

var _streams := {}
var _players: Array[AudioStreamPlayer] = []
var _next := 0


func _ready() -> void:
	for i in 8:
		var p := AudioStreamPlayer.new()
		p.volume_db = -6.0
		add_child(p)
		_players.append(p)
	# Chaque note : [fréquence de départ, fréquence d'arrivée, durée]
	_streams["click"] = _make([[520, 760, 0.05]], "square", 0.16)
	_streams["pop"] = _make([[380, 900, 0.09]], "sine", 0.5)
	_streams["type"] = _make([[900, 1150, 0.035]], "tri", 0.35)
	_streams["error"] = _make([[190, 150, 0.12], [150, 95, 0.16]], "square", 0.18)
	_streams["good"] = _make([[523, 523, 0.07], [659, 659, 0.07], [784, 784, 0.07], [1046, 1046, 0.16]], "tri", 0.4)
	_streams["word"] = _make([[660, 990, 0.07], [990, 1480, 0.12]], "sine", 0.45)
	_streams["win"] = _make([[523, 523, 0.1], [659, 659, 0.1], [784, 784, 0.1], [1046, 1046, 0.1], [784, 784, 0.08], [1046, 1046, 0.35]], "tri", 0.45)
	_streams["unlock"] = _make([[700, 1400, 0.12], [1400, 2100, 0.2]], "sine", 0.4)
	_streams["locked"] = _make([[230, 200, 0.06], [0, 0, 0.03], [230, 200, 0.06]], "square", 0.14)
	_streams["whoosh"] = _make([[0, 0, 0.16]], "noise", 0.07)


func play(sound: String, pitch := 1.0) -> void:
	var stream: AudioStream = _streams.get(sound)
	if stream == null:
		return
	var p := _players[_next]
	_next = (_next + 1) % _players.size()
	p.stream = stream
	p.pitch_scale = pitch * randf_range(0.97, 1.03)
	p.play()


func _make(notes: Array, wave: String, volume: float) -> AudioStreamWAV:
	var bytes := PackedByteArray()
	for note: Array in notes:
		var f0: float = note[0]
		var f1: float = note[1]
		var count := int(note[2] * RATE)
		var phase := 0.0
		for i in count:
			var t := float(i) / count
			phase += lerpf(f0, f1, t) / RATE
			var v := 0.0
			match wave:
				"square":
					v = 1.0 if fmod(phase, 1.0) < 0.5 else -1.0
				"tri":
					v = 4.0 * absf(fmod(phase, 1.0) - 0.5) - 1.0
				"noise":
					v = randf_range(-1.0, 1.0) * sin(t * PI)
				_:
					v = sin(phase * TAU)
			if f0 == 0 and wave != "noise":
				v = 0.0
			var env := minf(1.0, i / (RATE * 0.004)) * pow(1.0 - t, 1.5)
			var s := int(clampf(v * env * volume, -1.0, 1.0) * 32767)
			bytes.append(s & 0xFF)
			bytes.append((s >> 8) & 0xFF)
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = RATE
	wav.stereo = false
	wav.data = bytes
	return wav
