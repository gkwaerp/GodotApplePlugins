DOC_CLASSES := $(abspath ../doc_classes)

run:
	python3 make_rst.py -o docs -l "en" --filter "$(DOC_CLASSES)" --allow-warnings "$(HOME)/cvs/master-godot/editor/doc/classes" $(DOC_CLASSES)
	python3 postprocess_rst.py docs

html: run
	sphinx-build -b html docs ../docs
	# Ensure GitHub Pages serves directories prefixed with "_".
	touch ../docs/.nojekyll
