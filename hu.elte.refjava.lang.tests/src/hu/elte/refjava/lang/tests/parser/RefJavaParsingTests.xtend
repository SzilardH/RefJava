package hu.elte.refjava.lang.tests.parser

import com.google.inject.Inject
import hu.elte.refjava.lang.refJava.AssignmentList
import hu.elte.refjava.lang.refJava.File
import hu.elte.refjava.lang.refJava.MetaVariableType
import hu.elte.refjava.lang.refJava.PBlockExpression
import hu.elte.refjava.lang.refJava.PConstructorCall
import hu.elte.refjava.lang.refJava.PExpression
import hu.elte.refjava.lang.refJava.PFeatureCall
import hu.elte.refjava.lang.refJava.PMemberFeatureCall
import hu.elte.refjava.lang.refJava.PMetaVariable
import hu.elte.refjava.lang.refJava.PMethodDeclaration
import hu.elte.refjava.lang.refJava.PNothingExpression
import hu.elte.refjava.lang.refJava.PReturnExpression
import hu.elte.refjava.lang.refJava.PTargetExpression
import hu.elte.refjava.lang.refJava.PVariableDeclaration
import hu.elte.refjava.lang.refJava.Pattern
import hu.elte.refjava.lang.refJava.SchemeInstanceRule
import hu.elte.refjava.lang.refJava.SchemeType
import hu.elte.refjava.lang.tests.RefJavaInjectorProvider
import org.eclipse.xtext.testing.InjectWith
import org.eclipse.xtext.testing.extensions.InjectionExtension
import org.eclipse.xtext.testing.util.ParseHelper
import org.eclipse.xtext.xbase.XExpression
import org.junit.jupiter.api.Test
import org.junit.jupiter.api.^extension.ExtendWith

import static org.junit.jupiter.api.Assertions.*

@ExtendWith(InjectionExtension)
@InjectWith(RefJavaInjectorProvider)
class RefJavaParsingTests {
	
	@Inject extension ParseHelper<File> parseHelper
	
	@Test
	def void parseFile() {
		val file = '''
			package file.test;
		'''.parse
		
		assertTrue(file instanceof File)
		assertEquals(file.name, "file.test")	
	}
	
	@Test
	def void parseAllSchemeTypes() {
		val file = '''
			package file.test;
			local refactoring localTest()
				nothing
				~~~~~~~
				nothing
				
			block refactoring blockTest()
				nothing
				~~~~~~~
				nothing
				
			lambda refactoring lambdaTest()
				nothing
				~~~~~~~
				nothing
				
			class refactoring classTest()
				nothing
				~~~~~~~
				nothing
		'''.parse
		
		assertTrue(file.refactorings.forall[it instanceof SchemeInstanceRule])
		assertEquals((file.refactorings.get(0) as SchemeInstanceRule).type, SchemeType.LOCAL)
		assertEquals((file.refactorings.get(0) as SchemeInstanceRule).name, "localTest")
		assertEquals((file.refactorings.get(1) as SchemeInstanceRule).type, SchemeType.BLOCK)
		assertEquals((file.refactorings.get(1) as SchemeInstanceRule).name, "blockTest")
		assertEquals((file.refactorings.get(2) as SchemeInstanceRule).type, SchemeType.LAMBDA)
		assertEquals((file.refactorings.get(2) as SchemeInstanceRule).name, "lambdaTest")
		assertEquals((file.refactorings.get(3) as SchemeInstanceRule).type, SchemeType.CLASS)
		assertEquals((file.refactorings.get(3) as SchemeInstanceRule).name, "classTest")
	}
	
	
	@Test
	def void parseSchemeProperties() {
		val file = '''
			package file.test;
			local refactoring test()
				nothing
				~~~~~~~
				nothing
			target
				nothing
			definition
				nothing
			when
				assignment
					name#test  = "TEST"
				precondition
					true
		'''.parse
		
		val refactoring = file.refactorings.head as SchemeInstanceRule
		
		assertTrue(refactoring.matchingPattern instanceof Pattern)
		assertTrue(refactoring.replacementPattern instanceof Pattern)
		assertFalse(refactoring.targetPattern === null)
		assertTrue(refactoring.targetPattern instanceof Pattern)
		assertFalse(refactoring.definitionPattern === null)
		assertTrue(refactoring.definitionPattern instanceof Pattern)
		assertFalse(refactoring.assignments === null)
		assertTrue(refactoring.assignments instanceof AssignmentList)
		assertFalse(refactoring.precondition === null)
		assertTrue(refactoring.precondition instanceof XExpression)
	}
	
	@Test
	def void parsePatternExpressions() {
		val file = '''
			package file.test;
			local refactoring test()
				#s ; target ; return ; nothing ; { } ; public int a ; public void f() { } ; method() ; A.method() ; new F() { }
				~~~~~~~
				nothing
		'''.parse
		
		val pattern = (file.refactorings.head as SchemeInstanceRule).matchingPattern
		assertFalse(pattern.patterns === null)
		assertTrue(pattern.patterns.forall[it instanceof PExpression])
		
		val patterns = pattern.patterns
		assertTrue(patterns.get(0) instanceof PMetaVariable)
		assertTrue(patterns.get(1) instanceof PTargetExpression)
		assertTrue(patterns.get(2) instanceof PReturnExpression)
		assertTrue(patterns.get(3) instanceof PNothingExpression)
		assertTrue(patterns.get(4) instanceof PBlockExpression)
		assertTrue(patterns.get(5) instanceof PVariableDeclaration)
		assertTrue(patterns.get(6) instanceof PMethodDeclaration)
		assertTrue(patterns.get(7) instanceof PFeatureCall)
		assertTrue(patterns.get(8) instanceof PMemberFeatureCall)
		assertTrue(patterns.get(9) instanceof PConstructorCall)
	}
	
	@Test
	def void parseMetaVariables() {
		val file = '''
			package file.test;
			local refactoring test()
				#s ; name#n ; type#t ; visibility#v ; argument#a.. ; parameter#p..
				~~~~~~~
				nothing
		'''.parse
		
		val patterns = (file.refactorings.head as SchemeInstanceRule).matchingPattern.patterns
		assertTrue(patterns.forall[it instanceof PMetaVariable])
		
		assertEquals((patterns.get(0) as PMetaVariable).type, MetaVariableType.CODE)
		assertEquals((patterns.get(1) as PMetaVariable).type, MetaVariableType.NAME)
		assertEquals((patterns.get(2) as PMetaVariable).type, MetaVariableType.TYPE)
		assertEquals((patterns.get(3) as PMetaVariable).type, MetaVariableType.VISIBILITY)
		assertEquals((patterns.get(4) as PMetaVariable).type, MetaVariableType.ARGUMENT)
		assertEquals((patterns.get(5) as PMetaVariable).type, MetaVariableType.PARAMETER)
	}	
}
