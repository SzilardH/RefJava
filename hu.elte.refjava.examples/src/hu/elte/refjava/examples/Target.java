package hu.elte.refjava.examples;

class A {
}

class B extends A {
	int b;
	int a;
	
	void f() {
		int x = 1;
		int a;
		a = x;
		g();
		int y = 0;
		a = y;
	}
	
	void g() {
		a = b = 0;
	}
}