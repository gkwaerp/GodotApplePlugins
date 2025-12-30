DOC_CLASSES := $(abspath ../doc_classes)

run:
	python3 make_rst.py -o docs -l "en" --filter "$(DOC_CLASSES)" --allow-warnings "$(HOME)/cvs/master-godot/editor/doc/classes" $(DOC_CLASSES)

html: run
	sphinx-build -b html -c . docs ../docs
