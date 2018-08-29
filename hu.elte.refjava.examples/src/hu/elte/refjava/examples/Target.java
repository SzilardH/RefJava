package hu.elte.refjava.examples;

public class Target {
	int a;

	/*
	 * Insert a new block after the 3rd statement
	 * and move the first 3 statements into it.
	 * Change the 4th 'a' reference to 'this.a'
	 * and try again the last step.
	 */
	void f() {
		int a = 5;
		int b = a;
		System.out.println(a + b);
		System.out.println(a);
	}
}
