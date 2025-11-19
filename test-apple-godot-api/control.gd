extends Control

var gameCenter: GameCenterManager
var local: GKLocalPlayer

func _ready() -> void:
	gameCenter = GameCenterManager.new()
	local = gameCenter.local_player
	#gameCenter.load_leaderboards(["BOARD_1", "BOARD_2"])
	print("ONREADY: game center, is %s" % gameCenter)
	print("ONREADY: local, is auth: %s" % local.is_authenticated)
	print("ONREADY: local, player ID: %s" % local.game_player_id)

func _on_button_pressed() -> void:
	var player = gameCenter.local_player
	print("Got %s" % player)
	print("Fetching the other object: %s" % player.is_authenticated)
	
	gameCenter.authentication_error.connect(func(error: String) -> void:
		$auth_result.text = error
		)
	gameCenter.authentication_result.connect(func(status: bool) -> void:
		print("")
		if status:
			$auth_result.text = player.display_name
			$auth_state.text = "Authenticated"
			gameCenter.local_player.load_photo(true, func(image: Image, error: Variant)->void:
				if error == null:
					$texture_rect.texture = ImageTexture.create_from_image(image)
				else:
					print(error)
				)
			local.load_friends(func(friends: Array[GKPlayer], error: Variant) -> void:
				if error == null:
					for friend in friends:
						print("Found friend: %s" % friend.display_name)
				else:
					print("Error loading friends: %s" % error)
			)
			GKAchievement.reset_achivements(func(error: Variant)->void:
				print("Reset status: %s" % error)
				)
		else:
			$auth_state.text = "Not Authenticated"
		)
	gameCenter.authenticate()
