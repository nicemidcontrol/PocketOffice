extends GutTest

func test_sanity() -> void:
	assert_eq(1 + 1, 2, "math still works")

func test_true_is_true() -> void:
	assert_true(true, "truth still works")
