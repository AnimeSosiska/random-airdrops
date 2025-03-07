# Random Airdrops
A mod for Project Zomboid creating a fully random airdrops to the server, and also fully customizable, you can change the loot tables, hours to remove, chance to spawn every hour, spawn coordinates and etc.

The mod is must be compatible with dedicated servers and singleplayer

### Features
- Airdrops never spawn above each other
- Airdrops doesnt despawn if player is close
- Message with direction to airdrop above player when airdrop plane is too far away
- Random radio frequency that tells if there's an airdrop going to be dropped (You can find it in random radios and walkie talkies)
- Airplane sound when the airdrop spawn
- If the servers closes, old airdrops will be deleted automatically (Configurable)
- Fully customizable loot table (see the github wiki)
- Fully customizable spawn coordinates (see the github wiki)

### How it works?
- The server random a chance if the chances hits ok then the airdrop coordinates is stored in "cache"
- if the cache have airdrops then the server starting ticking every 30 ticks to check if there is a player to spawn the airdrop (vehicles cannot spawn without a chunk been loading) in that specific position, also when the airdrop is created is removed from the cache
- if the chunk in that specific position is loaded then the airdrop will be created
- when the timer goes below the 0 the airdrop will be removed from the world and from the cache if not created yet, unless the player is loading the chunk of the airdrop
- when the server starts all old airdrops will be despawned when the chunk loads
