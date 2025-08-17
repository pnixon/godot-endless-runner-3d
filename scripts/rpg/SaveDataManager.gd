class_name SaveDataManager
extends Node

# Save file configuration
const SAVE_FILE_NAME = "legends_of_aetherion_save.dat"
const BACKUP_FILE_NAME = "legends_of_aetherion_backup.dat"
const SAVE_VERSION = "1.0.0"
const ENCRYPTION_KEY = "AetherionSaveKey2024"

# Save data
var current_save_data: Dictionary = {}
var auto_save_enabled: bool = true
var auto_save_interval: float = 30.0  # Auto-save every 30 seconds
var auto_save_timer: float = 0.0

# Cloud save integration (Google Play Games Services)
var cloud_save_enabled: bool = false
var cloud_save_pending: bool = false
var last_cloud_sync: String = ""

# Signals
signal save_completed(success: bool, message: String)
signal load_completed(success: bool, message: String)
signal cloud_sync_completed(success: bool, message: String)
signal save_corrupted(backup_available: bool)
signal auto_save_triggered()

func _ready():
	# Set up auto-save timer
	set_process(true)
	
	# Check for cloud save availability
	check_cloud_save_availability()

func _process(delta):
	if auto_save_enabled:
		auto_save_timer += delta
		if auto_save_timer >= auto_save_interval:
			auto_save_timer = 0.0
			auto_save_game()

func save_game(player_data: PlayerData, force_cloud_sync: bool = false) -> bool:
	"""Save the game data locally and optionally to cloud"""
	print("Saving game data...")
	
	# Prepare save data
	var save_data = prepare_save_data(player_data)
	
	# Save locally
	var local_success = save_local(save_data)
	
	if local_success:
		# Create backup
		create_backup()
		
		# Sync to cloud if enabled
		if cloud_save_enabled and (force_cloud_sync or should_sync_to_cloud()):
			sync_to_cloud(save_data)
		
		save_completed.emit(true, "Game saved successfully")
		print("Game saved successfully")
		return true
	else:
		save_completed.emit(false, "Failed to save game")
		print("Failed to save game")
		return false

func load_game() -> PlayerData:
	"""Load game data, trying cloud first if available, then local"""
	print("Loading game data...")
	
	var player_data: PlayerData = null
	var load_source = "none"
	
	# Try cloud save first if available
	if cloud_save_enabled:
		player_data = load_from_cloud()
		if player_data:
			load_source = "cloud"
	
	# Fall back to local save
	if not player_data:
		player_data = load_local()
		if player_data:
			load_source = "local"
	
	# Try backup if main save failed
	if not player_data:
		player_data = load_backup()
		if player_data:
			load_source = "backup"
	
	if player_data:
		load_completed.emit(true, "Game loaded from " + load_source)
		print("Game loaded successfully from ", load_source)
		return player_data
	else:
		load_completed.emit(false, "No save data found")
		print("No save data found, creating new game")
		return create_new_player_data()

func prepare_save_data(player_data: PlayerData) -> Dictionary:
	"""Prepare save data with metadata and validation"""
	var save_data = {
		"version": SAVE_VERSION,
		"timestamp": Time.get_unix_time_from_system(),
		"date_string": Time.get_datetime_string_from_system(),
		"player_data": player_data.get_save_data(),
		"checksum": ""
	}
	
	# Calculate checksum for validation
	save_data["checksum"] = calculate_checksum(save_data["player_data"])
	
	return save_data

func save_local(save_data: Dictionary) -> bool:
	"""Save data to local file with encryption"""
	var file = FileAccess.open("user://" + SAVE_FILE_NAME, FileAccess.WRITE)
	if not file:
		print("Failed to open save file for writing")
		return false
	
	# Convert to JSON and encrypt
	var json_string = JSON.stringify(save_data)
	var encrypted_data = encrypt_data(json_string)
	
	file.store_string(encrypted_data)
	file.close()
	
	print("Local save completed")
	return true

func load_local() -> PlayerData:
	"""Load data from local file with decryption and validation"""
	if not FileAccess.file_exists("user://" + SAVE_FILE_NAME):
		print("Local save file does not exist")
		return null
	
	var file = FileAccess.open("user://" + SAVE_FILE_NAME, FileAccess.READ)
	if not file:
		print("Failed to open save file for reading")
		return null
	
	var encrypted_data = file.get_as_text()
	file.close()
	
	# Decrypt and parse
	var json_string = decrypt_data(encrypted_data)
	if json_string.is_empty():
		print("Failed to decrypt save data")
		save_corrupted.emit(FileAccess.file_exists("user://" + BACKUP_FILE_NAME))
		return null
	
	var json = JSON.new()
	var parse_result = json.parse(json_string)
	if parse_result != OK:
		print("Failed to parse save data JSON")
		save_corrupted.emit(FileAccess.file_exists("user://" + BACKUP_FILE_NAME))
		return null
	
	var save_data = json.data
	
	# Validate save data
	if not validate_save_data(save_data):
		print("Save data validation failed")
		save_corrupted.emit(FileAccess.file_exists("user://" + BACKUP_FILE_NAME))
		return null
	
	# Create PlayerData from save
	var player_data = PlayerData.new()
	player_data.load_save_data(save_data["player_data"])
	
	print("Local save loaded successfully")
	return player_data

func create_backup() -> bool:
	"""Create a backup of the current save file"""
	if not FileAccess.file_exists("user://" + SAVE_FILE_NAME):
		return false
	
	var source = FileAccess.open("user://" + SAVE_FILE_NAME, FileAccess.READ)
	if not source:
		return false
	
	var backup = FileAccess.open("user://" + BACKUP_FILE_NAME, FileAccess.WRITE)
	if not backup:
		source.close()
		return false
	
	backup.store_string(source.get_as_text())
	source.close()
	backup.close()
	
	print("Backup created successfully")
	return true

func load_backup() -> PlayerData:
	"""Load data from backup file"""
	if not FileAccess.file_exists("user://" + BACKUP_FILE_NAME):
		print("Backup file does not exist")
		return null
	
	print("Attempting to load from backup...")
	
	var file = FileAccess.open("user://" + BACKUP_FILE_NAME, FileAccess.READ)
	if not file:
		print("Failed to open backup file")
		return null
	
	var encrypted_data = file.get_as_text()
	file.close()
	
	# Decrypt and parse
	var json_string = decrypt_data(encrypted_data)
	if json_string.is_empty():
		print("Failed to decrypt backup data")
		return null
	
	var json = JSON.new()
	var parse_result = json.parse(json_string)
	if parse_result != OK:
		print("Failed to parse backup JSON")
		return null
	
	var save_data = json.data
	
	# Validate backup data
	if not validate_save_data(save_data):
		print("Backup data validation failed")
		return null
	
	# Create PlayerData from backup
	var player_data = PlayerData.new()
	player_data.load_save_data(save_data["player_data"])
	
	print("Backup loaded successfully")
	return player_data

func auto_save_game():
	"""Perform automatic save if player data is available"""
	var game_manager = get_tree().get_first_node_in_group("game_manager")
	if game_manager and game_manager.has_method("get_player_data"):
		var player_data = game_manager.get_player_data()
		if player_data:
			auto_save_triggered.emit()
			save_game(player_data, false)  # Don't force cloud sync for auto-saves

func validate_save_data(save_data: Dictionary) -> bool:
	"""Validate save data integrity"""
	# Check required fields
	if not save_data.has("version") or not save_data.has("player_data") or not save_data.has("checksum"):
		print("Save data missing required fields")
		return false
	
	# Check version compatibility
	if save_data["version"] != SAVE_VERSION:
		print("Save data version mismatch: ", save_data["version"], " vs ", SAVE_VERSION)
		# Could implement version migration here
		return false
	
	# Verify checksum
	var calculated_checksum = calculate_checksum(save_data["player_data"])
	if calculated_checksum != save_data["checksum"]:
		print("Save data checksum mismatch")
		return false
	
	return true

func calculate_checksum(data: Dictionary) -> String:
	"""Calculate a simple checksum for data validation"""
	var json_string = JSON.stringify(data)
	return json_string.md5_text()

func encrypt_data(data: String) -> String:
	"""Simple encryption for save data (not cryptographically secure)"""
	var encrypted = ""
	var key_index = 0
	
	for i in range(data.length()):
		var char_code = data.unicode_at(i)
		var key_char = ENCRYPTION_KEY.unicode_at(key_index % ENCRYPTION_KEY.length())
		encrypted += char(char_code ^ key_char)
		key_index += 1
	
	# Base64 encode to make it safe for file storage
	return Marshalls.utf8_to_base64(encrypted)

func decrypt_data(encrypted_data: String) -> String:
	"""Decrypt save data"""
	# Base64 decode first
	var decoded = Marshalls.base64_to_utf8(encrypted_data)
	if decoded.is_empty():
		return ""
	
	var decrypted = ""
	var key_index = 0
	
	for i in range(decoded.length()):
		var char_code = decoded.unicode_at(i)
		var key_char = ENCRYPTION_KEY.unicode_at(key_index % ENCRYPTION_KEY.length())
		decrypted += char(char_code ^ key_char)
		key_index += 1
	
	return decrypted

func create_new_player_data() -> PlayerData:
	"""Create a new PlayerData instance for new games"""
	var player_data = PlayerData.new()
	player_data.player_name = "Hero"
	player_data.current_chapter = 1
	
	# Set up initial stats
	if not player_data.stats:
		player_data.stats = PlayerStats.new()
	
	print("Created new player data")
	return player_data

# Cloud save functionality (Google Play Games Services integration)
func check_cloud_save_availability():
	"""Check if cloud save is available and enabled"""
	# This would integrate with Google Play Games Services
	# For now, we'll simulate the check
	cloud_save_enabled = false  # Will be enabled when Google Play Services is integrated
	print("Cloud save availability: ", cloud_save_enabled)

func should_sync_to_cloud() -> bool:
	"""Determine if we should sync to cloud based on various factors"""
	if not cloud_save_enabled:
		return false
	
	# Check if enough time has passed since last sync
	var current_time = Time.get_unix_time_from_system()
	var last_sync_time = Time.get_unix_time_from_datetime_string(last_cloud_sync) if not last_cloud_sync.is_empty() else 0
	var time_since_sync = current_time - last_sync_time
	
	# Sync every 5 minutes or on significant progress
	return time_since_sync > 300  # 5 minutes

func sync_to_cloud(save_data: Dictionary):
	"""Sync save data to Google Play Games Services"""
	if not cloud_save_enabled:
		return
	
	cloud_save_pending = true
	print("Syncing to cloud...")
	
	# This would integrate with Google Play Games Services
	# For now, we'll simulate the sync
	await get_tree().create_timer(1.0).timeout  # Simulate network delay
	
	# Simulate success/failure
	var success = true  # In real implementation, this would depend on the actual sync result
	
	if success:
		last_cloud_sync = Time.get_datetime_string_from_system()
		cloud_sync_completed.emit(true, "Cloud sync successful")
		print("Cloud sync completed successfully")
	else:
		cloud_sync_completed.emit(false, "Cloud sync failed")
		print("Cloud sync failed")
	
	cloud_save_pending = false

func load_from_cloud() -> PlayerData:
	"""Load save data from Google Play Games Services"""
	if not cloud_save_enabled:
		return null
	
	print("Loading from cloud...")
	
	# This would integrate with Google Play Games Services
	# For now, we'll return null to fall back to local save
	return null

func delete_save_data():
	"""Delete all save data (local and cloud)"""
	print("Deleting save data...")
	
	# Delete local files
	if FileAccess.file_exists("user://" + SAVE_FILE_NAME):
		DirAccess.remove_absolute("user://" + SAVE_FILE_NAME)
		print("Local save file deleted")
	
	if FileAccess.file_exists("user://" + BACKUP_FILE_NAME):
		DirAccess.remove_absolute("user://" + BACKUP_FILE_NAME)
		print("Backup file deleted")
	
	# Delete cloud save if available
	if cloud_save_enabled:
		delete_cloud_save()

func delete_cloud_save():
	"""Delete cloud save data"""
	if not cloud_save_enabled:
		return
	
	print("Deleting cloud save...")
	# This would integrate with Google Play Games Services
	# Implementation would depend on the specific API

func get_save_info() -> Dictionary:
	"""Get information about available saves"""
	var info = {
		"local_save_exists": FileAccess.file_exists("user://" + SAVE_FILE_NAME),
		"backup_exists": FileAccess.file_exists("user://" + BACKUP_FILE_NAME),
		"cloud_save_available": cloud_save_enabled,
		"cloud_save_pending": cloud_save_pending,
		"last_cloud_sync": last_cloud_sync,
		"auto_save_enabled": auto_save_enabled
	}
	
	# Get local save timestamp if it exists
	if info["local_save_exists"]:
		var file = FileAccess.open("user://" + SAVE_FILE_NAME, FileAccess.READ)
		if file:
			var encrypted_data = file.get_as_text()
			file.close()
			
			var json_string = decrypt_data(encrypted_data)
			if not json_string.is_empty():
				var json = JSON.new()
				if json.parse(json_string) == OK:
					var save_data = json.data
					if save_data.has("date_string"):
						info["local_save_date"] = save_data["date_string"]
	
	return info

func set_auto_save_enabled(enabled: bool):
	"""Enable or disable auto-save"""
	auto_save_enabled = enabled
	print("Auto-save ", "enabled" if enabled else "disabled")

func set_auto_save_interval(interval: float):
	"""Set the auto-save interval in seconds"""
	auto_save_interval = max(10.0, interval)  # Minimum 10 seconds
	auto_save_timer = 0.0  # Reset timer
	print("Auto-save interval set to ", auto_save_interval, " seconds")

func force_cloud_sync():
	"""Force an immediate cloud sync"""
	if not cloud_save_enabled:
		print("Cloud save not available")
		return
	
	var game_manager = get_tree().get_first_node_in_group("game_manager")
	if game_manager and game_manager.has_method("get_player_data"):
		var player_data = game_manager.get_player_data()
		if player_data:
			var save_data = prepare_save_data(player_data)
			sync_to_cloud(save_data)