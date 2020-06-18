package hu.elte.refjava.lang.tests.api

import hu.elte.refjava.lang.refJava.Visibility
import hu.elte.refjava.lang.tests.RefJavaInjectorProvider
import java.util.List
import java.util.Map
import org.eclipse.jdt.core.dom.ASTNode
import org.eclipse.jdt.core.dom.CompilationUnit
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

import static org.junit.jupiter.api.Assertions.*

@ExtendWith(InjectionExtension)
@InjectWith(RefJavaInjectorProvider)
package class ASTBuilderTests {
	
	Map<String, List<? extends ASTNode>> bindings = newHashMap
	Map<String, String> nameBindings = newHashMap
	Map<String, Type> typeBindings = newHashMap
	Map<String, List<SingleVariableDeclaration>> parameterBindings = newHashMap
	Map<String, Visibility> visibilityBindings = newHashMap
	Map<String, List<Expression>> argumentBindings = newHashMap
	String typeRefString = null
	
	List<ASTNode> replacement
	CompilationUnit source
	
	@Test
	def void variableDeclarationBuilderTest() {
			
		source = TestUtils.getCompliationUnit('''class A { public void f() { int a; char b; String str; } }''')
		val sourceVariableDeclarations = ((source.types.head as TypeDeclaration).bodyDeclarations.head as MethodDeclaration).body.statements.map[it as VariableDeclarationStatement]
		var List<VariableDeclarationStatement> replacementVariableDeclarations
		
		// #1
		typeRefString = "void|int|char|java.lang.String|"
		replacement = TestUtils.testBuilder('''public void f() { int a ; char b ; String str }''', 
												bindings, nameBindings, typeBindings, parameterBindings, visibilityBindings, argumentBindings, typeRefString)
		assertTrue(replacement.head instanceof MethodDeclaration)
		replacementVariableDeclarations = (replacement.head as MethodDeclaration).body.statements
		for(var int i = 0; i < replacementVariableDeclarations.size; i++) {
			assertTrue(replacementVariableDeclarations.get(i) instanceof VariableDeclarationStatement)
			assertEquals(replacementVariableDeclarations.get(i).toString, sourceVariableDeclarations.get(i).toString)
		}
		
		// #2
		typeRefString = "void|"
		nameBindings.put("N1", "a")
		nameBindings.put("N2", "b")
		nameBindings.put("N3", "str")
		typeBindings.put("T1", sourceVariableDeclarations.get(0).type)
		typeBindings.put("T2", sourceVariableDeclarations.get(1).type)
		typeBindings.put("T3", sourceVariableDeclarations.get(2).type)
		replacement = TestUtils.testBuilder('''public void f() { type#T1 name#N1 ; type#T2 name#N2 ; type#T3 name#N3 }''',
												bindings, nameBindings, typeBindings, parameterBindings, visibilityBindings, argumentBindings, typeRefString)
		assertTrue(replacement.head instanceof MethodDeclaration)
		replacementVariableDeclarations = (replacement.head as MethodDeclaration).body.statements
		for(var int i = 0; i < replacementVariableDeclarations.size; i++) {
			assertTrue(replacementVariableDeclarations.get(i) instanceof VariableDeclarationStatement)
			assertEquals(sourceVariableDeclarations.get(i).toString, replacementVariableDeclarations.get(i).toString)
		}
	}
	
	@Test
	def void fieldDeclarationBuilderTest() {
		
		source = TestUtils.getCompliationUnit('''class A { public int a; private char b; String str }''')
		val sourceFieldDeclarations = (source.types.head as TypeDeclaration).bodyDeclarations.map[it as FieldDeclaration]
		var List<FieldDeclaration> replacementFieldDeclarations
		
		// #1
		typeRefString = "int|char|java.lang.String|"
		replacement = TestUtils.testBuilder('''public int a ; private char b ; String str''', 
												bindings, nameBindings, typeBindings, parameterBindings, visibilityBindings, argumentBindings, typeRefString)
		assertTrue(replacement.forall[it instanceof FieldDeclaration])
		replacementFieldDeclarations = replacement.map[it as FieldDeclaration]
		for(var int i = 0; i < replacementFieldDeclarations.size; i++) {
			assertEquals(sourceFieldDeclarations.get(i).toString, replacementFieldDeclarations.get(i).toString)
		}
		
		// #2
		typeRefString = null
		nameBindings.put("N1", "a")
		nameBindings.put("N2", "b")
		nameBindings.put("N3", "str")
		typeBindings.put("T1", sourceFieldDeclarations.get(0).type)
		typeBindings.put("T2", sourceFieldDeclarations.get(1).type)
		typeBindings.put("T3", sourceFieldDeclarations.get(2).type)
		visibilityBindings.put("V1", Visibility.PUBLIC)
		visibilityBindings.put("V2", Visibility.PRIVATE)
		visibilityBindings.put("V3", Visibility.PACKAGE)
		replacement = TestUtils.testBuilder('''visibility#V1 type#T1 name#N1 ; visibility#V2 type#T2 name#N2 ; visibility#V3 type#T3 name#N3''', 
												bindings, nameBindings, typeBindings, parameterBindings, visibilityBindings, argumentBindings, typeRefString)
		assertTrue(replacement.forall[it instanceof FieldDeclaration])
		replacementFieldDeclarations = replacement.map[it as FieldDeclaration]
		for(var int i = 0; i < replacementFieldDeclarations.size; i++) {
			assertEquals(sourceFieldDeclarations.get(i).toString, replacementFieldDeclarations.get(i).toString)
		}
	}
	
	@Test
	def void methodDeclarationBuilderTest() {
		
		source = TestUtils.getCompliationUnit('''class A { public void f(int a){ } private short g(boolean l, char b){ } String h(){ } }''')
		val sourceMethodDeclarations = (source.types.head as TypeDeclaration).bodyDeclarations.map[it as MethodDeclaration]
		var List<MethodDeclaration> replacementMethodDeclarations
		
		// #1
		typeRefString = "void|int|short|boolean|char|java.lang.String|"
		replacement = TestUtils.testBuilder('''public void f(int a){ } ; private short g(boolean l, char b){ } ; String h(){ }''', 
												bindings, nameBindings, typeBindings, parameterBindings, visibilityBindings, argumentBindings, typeRefString)
		assertTrue(replacement.forall[it instanceof MethodDeclaration])
		replacementMethodDeclarations = replacement.map[it as MethodDeclaration]
		for(var int i = 0; i < replacementMethodDeclarations.size; i++) {
			assertEquals(sourceMethodDeclarations.get(i).toString, replacementMethodDeclarations.get(i).toString)
		}
		
		// #2
		typeRefString = null
		nameBindings.put("N1", "f")
		nameBindings.put("N2", "g")
		nameBindings.put("N3", "h")
		typeBindings.put("T1", sourceMethodDeclarations.get(0).returnType2)
		typeBindings.put("T2", sourceMethodDeclarations.get(1).returnType2)
		typeBindings.put("T3", sourceMethodDeclarations.get(2).returnType2)
		visibilityBindings.put("V1", Visibility.PUBLIC)
		visibilityBindings.put("V2", Visibility.PRIVATE)
		visibilityBindings.put("V3", Visibility.PACKAGE)
		parameterBindings.put("P1", sourceMethodDeclarations.get(0).parameters)
		parameterBindings.put("P2", sourceMethodDeclarations.get(1).parameters)
		parameterBindings.put("P3", sourceMethodDeclarations.get(2).parameters)
		replacement = TestUtils.testBuilder('''visibility#V1 type#T1 name#N1(parameter#P1..){ } ; visibility#V2 type#T2 name#N2(parameter#P2..){ } ; visibility#V3 type#T3 name#N3(parameter#P3..){ }''', 
												bindings, nameBindings, typeBindings, parameterBindings, visibilityBindings, argumentBindings, typeRefString)
		assertTrue(replacement.forall[it instanceof MethodDeclaration])
		replacementMethodDeclarations = replacement.map[it as MethodDeclaration]
		for(var int i = 0; i < replacementMethodDeclarations.size; i++) {
			assertEquals(sourceMethodDeclarations.get(i).toString, replacementMethodDeclarations.get(i).toString)
		}
	}
	
	@Test
	def void methodInvocetionAndConstructorCallBuilderTest() {
		
		source = TestUtils.getCompliationUnit('''class A { public void f() { new F() { public void apply(int a, char b) {} }.apply(a, b); new G() { public void apply() {} }.apply(); } int a = 1; char b = 'a'; }''')
		val sourceMethodInvocations = ((source.types.head as TypeDeclaration).bodyDeclarations.head as MethodDeclaration).body.statements.map[(it as ExpressionStatement).expression as MethodInvocation]
		var List<MethodInvocation> replacementMethodInvocations
		
		// #1
		typeRefString = "void|int|char|void|"
		argumentBindings.put("A1", sourceMethodInvocations.get(0).arguments)
		replacement = TestUtils.testBuilder('''new F() { public void apply(int a, char b) {} }.apply(argument#A1..) ; new G() { public void apply() {} }.apply()''', 
												bindings, nameBindings, typeBindings, parameterBindings, visibilityBindings, argumentBindings, typeRefString)
		assertTrue(replacement.forall[it instanceof ExpressionStatement] && replacement.forall[(it as ExpressionStatement).expression instanceof MethodInvocation])
		replacementMethodInvocations = replacement.map[(it as ExpressionStatement).expression as MethodInvocation]
		for(var int i = 0; i < replacementMethodInvocations.size; i++) {
			assertEquals(sourceMethodInvocations.get(i).toString, replacementMethodInvocations.get(i).toString)
		}
		
		// #2
		nameBindings.put("N1", "F")
		nameBindings.put("N2", "G")
		replacement = TestUtils.testBuilder('''new name#N1() { public void apply(int a, char b) {} }.apply(argument#A1..) ; new name#N2() { public void apply() {} }.apply()''', 
												bindings, nameBindings, typeBindings, parameterBindings, visibilityBindings, argumentBindings, typeRefString)
		assertTrue(replacement.forall[it instanceof ExpressionStatement] && replacement.forall[(it as ExpressionStatement).expression instanceof MethodInvocation])
		replacementMethodInvocations = replacement.map[(it as ExpressionStatement).expression as MethodInvocation]
		for(var int i = 0; i < replacementMethodInvocations.size; i++) {
			assertEquals(sourceMethodInvocations.get(i).toString, replacementMethodInvocations.get(i).toString)
		}							
	}
}