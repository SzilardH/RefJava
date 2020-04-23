package hu.elte.refjava.lang.tests

import hu.elte.refjava.api.patterns.ASTBuilder
import hu.elte.refjava.api.patterns.PatternParser
import hu.elte.refjava.lang.refJava.Pattern
import java.util.List
import org.eclipse.jdt.core.dom.ASTNode
import org.eclipse.jdt.core.dom.CompilationUnit
import org.eclipse.jdt.core.dom.FieldDeclaration
import org.eclipse.jdt.core.dom.MethodDeclaration
import org.eclipse.jdt.core.dom.TypeDeclaration
import org.eclipse.jdt.core.dom.VariableDeclarationFragment
import org.eclipse.jdt.core.dom.VariableDeclarationStatement
import org.eclipse.xtext.testing.InjectWith
import org.eclipse.xtext.testing.extensions.InjectionExtension
import org.junit.jupiter.api.Test
import org.junit.jupiter.api.^extension.ExtendWith

import static org.junit.jupiter.api.Assertions.*
import hu.elte.refjava.lang.refJava.PVariableDeclaration

@ExtendWith(InjectionExtension)
@InjectWith(RefJavaInjectorProvider)
package class ASTBuilderTests {
	
	val builder = new ASTBuilder(null)
	Pattern pattern
	CompilationUnit source
	String typeRefString
	List<ASTNode> replacement
	
	@Test
	def void variableDeclarationBuilderTest() {
		pattern = PatternParser.parse("public void f() { int a ; char b ; }")
		source = TestUtils.getCompliationUnit("class A { void f(){ int a; char b; } }")
		typeRefString = "void|int|char|"
		replacement = builder.build(pattern, source.AST, newHashMap, newHashMap, newHashMap, newHashMap, newHashMap, newHashMap, typeRefString)
		val variableDeclarations = (((source.types.head as TypeDeclaration).bodyDeclarations.head) as MethodDeclaration).body.statements
		
		assertTrue((replacement.head as MethodDeclaration).body.statements.forall[it instanceof VariableDeclarationStatement])
		assertEquals((pattern.patterns.head as PVariableDeclaration).name, 
			((((replacement.head as MethodDeclaration).body.statements.head as VariableDeclarationStatement).fragments.head as VariableDeclarationFragment).name.identifier))
		assertEquals((pattern.patterns.last as PVariableDeclaration).name, 
			((((replacement.head as MethodDeclaration).body.statements.last as VariableDeclarationStatement).fragments.head as VariableDeclarationFragment).name.identifier))
		assertEquals((variableDeclarations.head as VariableDeclarationStatement).type.toString, 
			(((replacement.head as MethodDeclaration).body.statements.head as VariableDeclarationStatement).type.toString))
		assertEquals((variableDeclarations.last as VariableDeclarationStatement).type.toString, 
			(((replacement.head as MethodDeclaration).body.statements.last as VariableDeclarationStatement).type.toString))
	}
	
	@Test
	def void fieldDeclarationBuilderTest() {
		pattern = PatternParser.parse("int a; char b;")
		source = TestUtils.getCompliationUnit("class A { public int a; private char b; }")
		typeRefString = "int|char|"
		replacement = builder.build(pattern, source.AST, newHashMap, newHashMap, newHashMap, newHashMap, newHashMap, newHashMap, typeRefString)
		val fieldDeclarations = (source.types.head as TypeDeclaration).bodyDeclarations
		
		assertTrue(replacement.forall[it instanceof FieldDeclaration])
		assertEquals((pattern.patterns.head as PVariableDeclaration).name, 
			((replacement.head as FieldDeclaration).fragments.head as VariableDeclarationFragment).name.identifier)
		assertEquals((pattern.patterns.last as PVariableDeclaration).name, 
			((replacement.last as FieldDeclaration).fragments.head as VariableDeclarationFragment).name.identifier)
		assertEquals((fieldDeclarations.head as FieldDeclaration).type.toString, 
			((replacement.head as FieldDeclaration).type.toString))
		assertEquals((fieldDeclarations.last as FieldDeclaration).type.toString, 
			((replacement.last as FieldDeclaration).type.toString))
	}
	
	@Test
	def void methodDeclarationBuilderTest() {
		
		fail("not implemented")
		
	}
	
	@Test
	def void constructorCallBuilderTest() {
		
		fail("not implemented")
		
		
	}
	
	@Test
	def void methodInvocationBuilderTest() {
		
		fail("not implemented")
		
		
		
	}
	
	
}