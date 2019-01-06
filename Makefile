BUILD_DIR=build
SRC_DIR=cpt
TEST_DIR=tests
REPORTS_DIR=reports

build: cpt/*.pyx
	python3 setup.py build_ext --inplace
	mkdir -p ${REPORTS_DIR}
	mv ${SRC_DIR}/*.html ${REPORTS_DIR}

build-cov: cptCython/*.pyx
	python3 setup.py build_ext --inplace --define CYTHON_TRACE
	mkdir -p ${REPORTS_DIR}
	mv ${SRC_DIR}/*.html ${REPORTS_DIR}

clean:
	rm -rf ${BUILD_DIR}/
	rm -f ${SRC_DIR}/*.c
	find . -name "*.so" -exec rm {} \;
	find . -name "*.html" -exec rm {} \;
	find . -name "*.c" -exec rm {} \;
	rm -rf ${REPORTS_DIR}

lint:
	pylint ${TEST_DIR}
	pycodestyle ${TEST_DIR} --max-line-length=100
	pylint profiling
	pycodestyle profiling --max-line-length=100 --ignore=E402
	pylint tests_scripts
	pycodestyle tests_scripts --max-line-length=100

test:
	pytest
	pytest tests_scripts