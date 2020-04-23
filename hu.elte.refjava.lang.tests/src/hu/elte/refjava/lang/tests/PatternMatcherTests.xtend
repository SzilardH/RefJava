package hu.elte.refjava.lang.tests

import hu.elte.refjava.api.patterns.PatternMatcher
import hu.elte.refjava.api.patterns.PatternParser
import hu.elte.refjava.lang.refJava.Pattern
import org.eclipse.jdt.core.dom.CompilationUnit
import org.eclipse.jdt.core.dom.MethodDeclaration
import org.eclipse.jdt.core.dom.TypeDeclaration
import org.eclipse.xtext.testing.InjectWith
import org.eclipse.xtext.testing.extensions.InjectionExtension
import org.junit.jupiter.api.Test
import org.junit.jupiter.api.^extension.ExtendWith

import static org.junit.jupiter.api.Assertions.*

@ExtendWith(InjectionExtension)
@InjectWith(RefJavaInjectorProvider)
package class PatternMatcherTests {
	
	val matcher = new PatternMatcher(null)
	Pattern pattern
	CompilationUnit source
	
	@Test
	def void variableDeclarationMatcherTest() {
		pattern = PatternParser.parse("type#T1 name#N1 ; type#T2 name#N2 ;")
		source = TestUtils.getCompliationUnit("class A { void f(){ int a; char b; } }")
		val block = ((source.types.head as TypeDeclaration).bodyDeclarations.head as MethodDeclaration).body
		assertTrue(matcher.match(pattern, block.statements, newHashMap, newHashMap, newHashMap, newHashMap, newHashMap, null))
	}
	
	@Test
	def void fieldDeclarationMatcherTest() {
		pattern = PatternParser.parse("visibility#V1 type#T1 name#N1 ; visibility#V2 type#T2 name#N2 ;")
		source = TestUtils.getCompliationUnit("class A { public int a ; private char b; } }")
		val typeDecl = (source.types.head as TypeDeclaration)
		assertTrue(matcher.match(pattern, typeDecl.bodyDeclarations, newHashMap, newHashMap, newHashMap, newHashMap, newHashMap, null))
	}
	
	@Test
	def void methodDeclarationMatcherTest() {
		pattern = PatternParser.parse("visibility#V1 type#T1 name#N1() {} ; visibility#V2 type#T2 name#N2() {} ;")
		source = TestUtils.getCompliationUnit("class A { public void f() {} private int g() {} }")
		val typeDecl = (source.types.head as TypeDeclaration)
		assertTrue(matcher.match(pattern, typeDecl.bodyDeclarations, newHashMap, newHashMap, newHashMap, newHashMap, newHashMap, null))
	}
	
	@Test
	def void methodInvocationTest() {
		pattern = PatternParser.parse("new name#N1() { visibility#V1 type#T1 name#N2() {} }.name#N3()")
		source = TestUtils.getCompliationUnit("class A { public void f() { new F() { public void apply() {} }.apply(); } }")
		val block = ((source.types.head as TypeDeclaration).bodyDeclarations.head as MethodDeclaration).body
		assertTrue( matcher.match(pattern, block.statements, newHashMap, newHashMap, newHashMap, newHashMap, newHashMap, null))
	}
	
	
	
	
	
	
	
}