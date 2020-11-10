package hu.elte.refjava.lang.tests.api

import hu.elte.refjava.lang.refJava.Visibility
import hu.elte.refjava.lang.tests.RefJavaInjectorProvider
import java.util.List
import java.util.Map
import org.eclipse.jdt.core.dom.ClassInstanceCreation
import org.eclipse.jdt.core.dom.Expression
import org.eclipse.jdt.core.dom.ExpressionStatement
import org.eclipse.jdt.core.dom.FieldDeclaration
import org.eclipse.jdt.core.dom.MethodDeclaration
import org.eclipse.jdt.core.dom.MethodInvocation
import org.eclipse.jdt.core.dom.SingleVariableDeclaration
import org.eclipse.jdt.core.dom.Type
import org.eclipse.jdt.core.dom.TypeDeclaration
import org.eclipse.jdt.core.dom.VariableDeclarationStatement
import org.eclipse.xtext.testing.InjectWith
import org.eclipse.xtext.testing.extensions.InjectionExtension
import org.junit.jupiter.api.Test
import org.junit.jupiter.api.^extension.ExtendWith

@ExtendWith(InjectionExtension)
@InjectWith(RefJavaInjectorProvider)
package class PatternMatcherTests {
	
	Map<String, String> nameBindings = newHashMap
	Map<String, Type> typeBindings = newHashMap
	Map<String, List<SingleVariableDeclaration>> parameterBindings = newHashMap
	Map<String, Visibility> visibilityBindings = newHashMap
	Map<String, List<Expression>> argumentBindings = newHashMap
	String typeRefString = null
	
	@Test
	def void variableDeclarationMatcherTest() {
		// #1
		TestUtils.testMatcher('''type#T1 name#N1 ; type#T2 name#N2 ;''',
								'''
								class A {
									void f(){
										int a;
										char b;
									}
								}
								''', 
								"block", 
								nameBindings , typeBindings, parameterBindings, visibilityBindings, argumentBindings, typeRefString)
		
		// #2
		val compUnit = TestUtils.getCompliationUnit("class A { void f(){ int a; char b; } }")
		val methodBody = ((compUnit.types.head as TypeDeclaration).bodyDeclarations.head as MethodDeclaration).body.statements
		nameBindings.put("N1", "a")
		nameBindings.put("N2", "b")
		typeBindings.put("T1", (methodBody.head as VariableDeclarationStatement).type )
		typeBindings.put("T2", (methodBody.last as VariableDeclarationStatement).type )
		TestUtils.testMatcher('''type#T1 name#N1 ; type#T2 name#N2 ;''', 
								'''
								class A {
									void f(){
										int a;
										char b;
									}
								}
								''', 
								"block", 
								nameBindings , typeBindings, parameterBindings, visibilityBindings, argumentBindings, typeRefString)
		
		// #3
		typeRefString="int|char|java.lang.String|"
		TestUtils.testMatcher('''int a ; char b ; String c ;''', 
								'''
								class A {
									void f(){
										int a;
										char b;
										String c;
									}
								}
								''',
								"block", 
								nameBindings , typeBindings, parameterBindings, visibilityBindings, argumentBindings, typeRefString)
	}
	
	@Test
	def void fieldDeclarationMatcherTest() {
		// #1
		TestUtils.testMatcher('''visibility#V1 type#T1 name#N1 ; visibility#V2 type#T2 name#N2 ;''', 
								'''
								class A {
									public int a;
									private char b;
								}
								''', 
								"class", 
								nameBindings , typeBindings, parameterBindings, visibilityBindings, argumentBindings, typeRefString)
		
		// #2
		val compUnit = TestUtils.getCompliationUnit("class A { public int a; private char b; }")
		val fieldDeclarations = (compUnit.types.head as TypeDeclaration).bodyDeclarations
		nameBindings.put("N1", "a")
		nameBindings.put("N2", "b")
		typeBindings.put("T1", (fieldDeclarations.head as FieldDeclaration).type )
		typeBindings.put("T2", (fieldDeclarations.last as FieldDeclaration).type )
		visibilityBindings.put("V1", Visibility.PUBLIC)
		visibilityBindings.put("V2", Visibility.PRIVATE)
		TestUtils.testMatcher('''visibility#V1 type#T1 name#N1 ; visibility#V2 type#T2 name#N2 ;''', 
								'''
								class A {
									public int a ;
									private char b;
								}
								''', 
								"class", 
								nameBindings , typeBindings, parameterBindings, visibilityBindings, argumentBindings, typeRefString)
		
		// #3
		typeRefString = "int|char|"
		TestUtils.testMatcher('''public int a ; private char b ;''', 
								'''
								class A {
									public int a ;
									private char b;
								}
								''',
								"class", 
								nameBindings , typeBindings, parameterBindings, visibilityBindings, argumentBindings, typeRefString)
	}
	
	@Test
	def void methodDeclarationMatcherTest() {
		// #1
		TestUtils.testMatcher('''visibility#V1 type#T1 name#N1(parameter#P1..) {} ; visibility#V2 type#T2 name#N2(parameter#P2..) {} ;''', 
								'''
								class A { 
									public void f(int a, String str) {} 
									private int g() {}
								}
								''', 
								"class", 
								nameBindings , typeBindings, parameterBindings, visibilityBindings, argumentBindings, typeRefString)
		
		// #2
		val compUnit = TestUtils.getCompliationUnit("class A { public void f(int a, String str) {} private int g() {} }")
		val methodDeclarations = (compUnit.types.head as TypeDeclaration).bodyDeclarations
		nameBindings.put("N1", "f")
		nameBindings.put("N2", "g")
		typeBindings.put("T1", (methodDeclarations.head as MethodDeclaration).returnType2 )
		typeBindings.put("T2", (methodDeclarations.last as MethodDeclaration).returnType2 )
		visibilityBindings.put("V1", Visibility.PUBLIC)
		visibilityBindings.put("V2", Visibility.PRIVATE)
		parameterBindings.put("P1", (methodDeclarations.head as MethodDeclaration).parameters)
		parameterBindings.put("P2", (methodDeclarations.last as MethodDeclaration).parameters)
		
		TestUtils.testMatcher('''visibility#V1 type#T1 name#N1(parameter#P1..) {} ; visibility#V2 type#T2 name#N2(parameter#P2..) {} ;''', 
								'''
								class A { 
									public void f(int a, String str) {}
									private int g() {}
								}
								''', 
								"class",
								nameBindings , typeBindings, parameterBindings, visibilityBindings, argumentBindings, typeRefString)
		
		// #3
		typeRefString = "void|int|java.lang.String|int|"
		TestUtils.testMatcher('''public void f(int a, String str) {} ; private int g() {} ;''', 
								'''
								class A { 
									public void f(int a, String str) {}
									private int g() {}
								}
								''', 
								"class",
								nameBindings , typeBindings, parameterBindings, visibilityBindings, argumentBindings, typeRefString)	
	}
	
	@Test
	def void methodInvocationAndConstructorCallMatcherTest() {
		// #1
		TestUtils.testMatcher('''new name#N1() { visibility#V1 type#T1 name#N2(parameter#P1..) {} }.name#N2(argument#A1..)''', 
								'''
								class A {
									void f() {
										new F() {
											public void apply(int a) {}
										}.apply(a);
									}
									public int a = 1;
								}
								''', 
								"block", 
								nameBindings , typeBindings, parameterBindings, visibilityBindings, argumentBindings, typeRefString)
		
		// #2
		val compUnit = TestUtils.getCompliationUnit("class A { public void f() { new F() { public void apply(int a, char b) {} }.apply(a, b); } int a = 1; char b = 'a'; }")
		val methodInvocation = (((compUnit.types.head as TypeDeclaration).bodyDeclarations.head as MethodDeclaration).body.statements.head as ExpressionStatement).expression as MethodInvocation
		val method = (((((compUnit.types.head as TypeDeclaration).bodyDeclarations.head as MethodDeclaration).body.statements.head as ExpressionStatement)
						.expression as MethodInvocation)
						.expression as ClassInstanceCreation)
						.anonymousClassDeclaration.bodyDeclarations.head as MethodDeclaration
		nameBindings.put("N1", "F")
		nameBindings.put("N2", "apply")
		typeBindings.put("T1", method.returnType2)
		visibilityBindings.put("V1", Visibility.PUBLIC)
		parameterBindings.put("P1", method.parameters)
		argumentBindings.put("A1", methodInvocation.arguments)
		TestUtils.testMatcher('''new name#N1() { visibility#V1 type#T1 name#N2(parameter#P1..) {} }.name#N2(argument#A1..)''', 
								'''
								class A {
									void f() {
										new F() {
											public void apply(int a, char b) {}
										}.apply(a, b);
									}
									int a = 1;
									char b = 'a';
								}
								''', 
								"block", 
								nameBindings , typeBindings, parameterBindings, visibilityBindings, argumentBindings, typeRefString)
		
		// #3
		typeRefString = "void|int|char|"
		TestUtils.testMatcher('''new F() { public void apply(int a, char b) {} }.apply(argument#A1..)''', 
								'''
								class A {
									void f() {
										new F() {
											public void apply(int a, char b) {}
										}.apply(a, b);
									}
								}
								int a = 1;
								char b = 'a';
								''',
								"block", 
								nameBindings , typeBindings, parameterBindings, visibilityBindings, argumentBindings, typeRefString)
	}
	
	
	
	
}