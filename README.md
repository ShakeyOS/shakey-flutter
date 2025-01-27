
![Header 01](https://github.com/user-attachments/assets/e3d3536c-bbe1-43c7-9de2-f8214be0308a)

# Welcome to the Shakey World!
Shakey OS is the first open source Mobile AI Framework based on ElizaOS for Flutter allowing people to build apps for IOS and Android with AI tooling and wallet integrated out of the box.


## ShakeyOS Guide (Flutter)
### Prerequisites
Before getting started with ShakyOS, ensure you have the following installed:
> Node.js 23+
> pnpm 9+
> Git for version control
> A code editor (VS Code or VSCodium recommended)

## Flutter Environment Setup
## Installation
### Clone and Install
> Before proceeding, check for the latest available stable version tag.
Clone the repository:
> git clone <repo-link>
Navigate to the project directory:
> cd shakey-flutter
Install dependencies (on initial run):
> pnpm install --no-frozen-lockfile

Build local libraries:
> pnpm build

### Configure Environment
Copy the example environment file:
> cp .env.example .env
> Edit .env and add your values:

# Suggested quick-start environment variables
> DISCORD_APPLICATION_ID=  # For Discord integration
> DISCORD_API_TOKEN=       # Bot token
> HEURIST_API_KEY=         # Heurist API key for LLM and image generation
> OPENAI_API_KEY=          # OpenAI API key
> GROK_API_KEY=            # Grok API key
> ELEVENLABS_XI_API_KEY=   # API key from ElevenLabs (for voice)
> LIVEPEER_GATEWAY_URL=    # Livepeer gateway URL

# Create Your First Agent

## Create a Character File
> Check out characters/trump.character.json or characters/tate.character.json as templates for creating and customizing your agent's personality and behavior. Additionally, you can review core/src/core/defaultCharacter.ts (in version 0.0.10, but post-refactor, it will be located in packages/core/src/defaultCharacter.ts).

## Start the Agent
### Specify which character you want to run:
> pnpm start --character="characters/trump.character.json"
To load multiple characters, use a comma-separated list:
> pnpm start --characters="characters/trump.character.json,characters/tate.character.json"

### Interact with the Agent
You're now ready to start a conversation with your agent! Open a new terminal window and begin interacting.
Flutter Setup 
> Ensure Flutter Environment is Set Up
> Install Dependencies
> Install the All dependencies for the base app flutter-shakey:
> pnpm flutter-get
Install all the dependencies for the example app:
> pnpm flutter-example-get
> Run App on Emulator (Android)

For the Base App:
> pnpm flutter-run

For the Example App:
> pnpm flutter-example-run

Now you’re all set up to develop with ShakyOS!
# Note - We are still early development and improving our systems, we would appreciate code contributions to make Shakey the best open source AI resource for mobile apps!
