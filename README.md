# Foundry VTT Translation Helper

`fvtt-translation-helper` is a utility designed to simplify the process of translating systems and modules in **Foundry VTT** using the [Babele](https://gitlab.com/riccisi/foundryvtt-babele) module. It provides tools to clean, extract, and merge translations from JSON files associated with Foundry VTT compendiums.

## Features

- **Remove Unnecessary Entries**: Delete entries from a JSON file that match specified patterns, helping to clean up unwanted data.
- **Create Key-Indexed Translation Files**: Generate a "flat" JSON file with keys and values that need to be translated, making it easy to split into smaller chunks for use with translators or AI tools like ChatGPT.
- **Merge Translations**: Combine the translated key-indexed file back into the original JSON structure for use with Foundry VTT.

## Usage

The utility provides three main commands: extract, remove, and merge. Below are detailed descriptions and examples of how to use each command.

### Extract

Extracts translatable values from a JSON file and creates a key-indexed file.

Command:

`fvtt-translation-helper extract --input <input_file> --output <output_file> -p <patterns>`

Example:

`fvtt-translation-helper extract --input ./Examples/clean-shadowdark.magic-items.json --output ./Examples/copies-shadowdark.magic-items.json -p entries~*~description -p entries~*~effects~*~name -p entries~*~name`

### Remove

Removes unnecessary entries from a JSON file based on provided patterns.

Command:

`fvtt-translation-helper remove --input <input_file> --output <output_file> -p <patterns>`

Example:

`fvtt-translation-helper remove --input ./Examples/shadowdark.magic-items.json --output ./Examples/clean-shadowdark.magic-items.json -p entries~*~effects~*~system -p entries~*~effects~*~duration -p entries~*~effects~*~origin -p entries~*~effects~*~tint -p entries~*~effects~*~transfer -p entries~*~effects~*~statuses -p entries~*~effects~*~sort -p entries~*~effects~*~flags -p entries~*~effects~*~_stats -p entries~*~effects~*~description -p entries~*~effects~*~disabled`

### Merge

Merges a translated key-indexed file back into the original JSON structure.

Command:

`fvtt-translation-helper merge --input <input_file> --merge-with <key_indexed_file> --output <output_file>`

Example:

`fvtt-translation-helper merge --input ./Examples/clean-shadowdark.magic-items.json --merge-with ./Examples/copies-shadowdark.magic-items.json --output ./Examples/translated.shadowdark.magic-items.json`

#### Patterns

Used in extract and remove commands to define which JSON keys should be targeted. Patterns are separated by ~, and * matches any key.

Examples of Patterns:

- `entries~*~description`: Matches all description keys nested under entries.
- `entries~*~effects~*~name`: Matches all name keys within effects under entries.

## Future Features

- **Enhanced Pattern-Matching Capabilities**: Improve the flexibility and expressiveness of pattern definitions for more complex JSON structures.
- **Integration with Translation Tools**: Add support for automated translation using services like Google Translate, ChatGPT, and DeepL.
- **File Splitting Helper**: Introduce a utility to split large key-indexed files into smaller chunks of a user-specified size for easier translation and management.

