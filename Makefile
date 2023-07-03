INPUT_DIR  := languages
OUTPUT_DIR := generated

gen-%: $(INPUT_DIR)/%
	bundle exec rake generate:dockerfile[$*] DIRECTORY=$(OUTPUT_DIR)

.PHONY: generate
generate:
	for lang in $(shell ls $(INPUT_DIR)); do make gen-$$lang; done
