package hu.elte.refjava.examples;

public class Target {
	int a;

	/*
	 * Insert a new block after the 3rd statement
	 * and move the first 3 statements into it.
	 * Change the 4th 'a' reference to 'this.a'
	 * and try again the last step.
	 */
	void f() 
	{
		int x;
		int a;
		{
			System.out.println("asd");
			int k;
		}
		int b;
		
	}
}


/*new F() {
public void apply() {
	System.out.println("ASD");
}
}.apply();*/

//interface F { void apply(); }