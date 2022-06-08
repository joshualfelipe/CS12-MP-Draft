# CS12-MP-Draft

- [ ] Potential Improvements
	- [ ] Refactor `update-egg-ongoing()` into separate functions
	- [ ] Combine `update-platforms-y()` and `egg-transition()` into `transition-stage()`
	- [ ] Egg keeps lightly moving on platform
		- This is due to the delay between the egg's dx and the current platform's dx updating.
		- Could modify `check-platform-side-collision()`
	- [ ] Refactor "Current platform" tracking logic
		- Seems convoluted
	- [ ] Documentation in `update-platform()`
		- Specifically the if statements
	- [ ] Modify `INITIAL-STATE` Logic to separate platform generation and egg copying