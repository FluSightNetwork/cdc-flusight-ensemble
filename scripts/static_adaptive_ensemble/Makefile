#mcandrew;

PYTHON := python3 -W ignore
R := Rscript --vanilla

../weights/static-regularized-weights.csv: create_static_regularized_weights.py
	$(R) create-scoring-period.R && \
	echo "scoring period created" && \
	$(PYTHON) create_static_regularized_weights.py && \
	echo "completed without error"




