package hu.elte.refjava.lang.tests.compiler

import org.junit.jupiter.api.^extension.ExtendWith
import org.eclipse.xtext.testing.InjectWith
import org.eclipse.xtext.testing.extensions.InjectionExtension
import hu.elte.refjava.lang.tests.RefJavaInjectorProvider
import com.google.inject.Inject
import org.eclipse.xtext.xbase.testing.CompilationTestHelper
import org.junit.jupiter.api.Test

@ExtendWith(InjectionExtension)
@InjectWith(RefJavaInjectorProvider)
class RefJavaCompilerTests {
	
	@Inject extension CompilationTestHelper
	
	@Test
	def void compileSchemeTypes() {
		'''
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
		'''.assertCompilesTo('''
			MULTIPLE FILES WERE GENERATED
			
			File 1 : /myProject/./src-gen/file/test/blockTest.java
			
			package file.test;
			
			import hu.elte.refjava.api.BlockRefactoring;
			
			@SuppressWarnings("all")
			public class blockTest extends BlockRefactoring {
			  public blockTest() {
			    super("nothing", "nothing");
			  }
			}
			
			File 2 : /myProject/./src-gen/file/test/classTest.java
			
			package file.test;
			
			import hu.elte.refjava.api.ClassRefactoring;
			
			@SuppressWarnings("all")
			public class classTest extends ClassRefactoring {
			  public classTest() {
			    super("nothing", "nothing");
			  }
			}
			
			File 3 : /myProject/./src-gen/file/test/lambdaTest.java
			
			package file.test;
			
			import hu.elte.refjava.api.LambdaRefactoring;
			
			@SuppressWarnings("all")
			public class lambdaTest extends LambdaRefactoring {
			  public lambdaTest() {
			    super("nothing", "nothing");
			  }
			}
			
			File 4 : /myProject/./src-gen/file/test/localTest.java
			
			package file.test;
			
			import hu.elte.refjava.api.LocalRefactoring;
			
			@SuppressWarnings("all")
			public class localTest extends LocalRefactoring {
			  public localTest() {
			    super("nothing", "nothing");
			  }
			}

		''')
	}
	
	@Test
	def void compileSchemeWithTargetClosure() {
		'''
			package test;
			
			block refactoring test()
				nothing
				~~~~~~~
				nothing
			target
				nothing
		'''
		.assertCompilesTo(
		'''
			package test;
			
			import hu.elte.refjava.api.BlockRefactoring;
			
			@SuppressWarnings("all")
			public class test extends BlockRefactoring {
			  public test() {
			    super("nothing", "nothing");
			  }
			  
			  @Override
			  protected boolean safeTargetCheck() {
			    return super.targetCheck("nothing");
			  }
			}
		''')
	}
	
	@Test
	def void compileSchemeWithPrecondition() {
		'''
			package test;
			
			local refactoring test()
				nothing
				~~~~~~~
				nothing
			when
				precondition
					isSingle(target) 
					&& true == true
		'''
		.assertCompilesTo(
		'''
			package test;
			
			import hu.elte.refjava.api.Check;
			import hu.elte.refjava.api.LocalRefactoring;
			
			@SuppressWarnings("all")
			public class test extends LocalRefactoring {
			  public test() {
			    super("nothing", "nothing");
			  }
			  
			  private boolean instanceCheck() {
			    return (Check.isSingle(bindings.get("target")) && (true == true));
			  }
			  
			  @Override
			  protected boolean check() {
			    return super.check() && instanceCheck();
			  }
			}
		''')
	}
	
	@Test
	def void compileSchemeWithAssignments() {
		'''
			package test;
			
			local refactoring test()
				nothing
				~~~~~~~
				nothing
			when
				assignment
					name#N = "TEST" ;
					type#T = type(target) ;
					visibility#V = visibility(target) ;
					parameter#P = parameters(target)
			
		'''
		.assertCompilesTo(
		'''
			package test;
			
			import hu.elte.refjava.api.Check;
			import hu.elte.refjava.api.LocalRefactoring;
			import hu.elte.refjava.lang.refJava.Visibility;
			import java.util.List;
			import org.eclipse.jdt.core.dom.SingleVariableDeclaration;
			import org.eclipse.jdt.core.dom.Type;
			
			@SuppressWarnings("all")
			public class test extends LocalRefactoring {
			  public test() {
			    super("nothing", "nothing");
			  }
			  
			  private String valueof_name_N() {
			    return "TEST";
			  }
			  
			  private void set_name_N() {
			    nameBindings.put("N", valueof_name_N());
			  }
			  
			  private Type valueof_type_T() {
			    Type _type = Check.type(bindings.get("target"));
			    return _type;
			  }
			  
			  private void set_type_T() {
			    typeBindings.put("T", valueof_type_T());
			  }
			  
			  private List valueof_visibility_V() {
			    Visibility _visibility = Check.visibility(bindings.get("target"));
			    return _visibility;
			  }
			  
			  private void set_visibility_V() {
			    visibilityBindings.put("V", valueof_visibility_V());
			  }
			  
			  private List valueof_parameter_P() {
			    List<SingleVariableDeclaration> _parameters = Check.parameters(bindings.get("target"));
			    return _parameters;
			  }
			  
			  private void set_parameter_P() {
			    parameterBindings.put("P", valueof_parameter_P());
			  }
			  
			  protected void setMetaVariables() {
			    set_name_N();
			    set_type_T();
			    set_visibility_V();
			    set_parameter_P();
			    
			    super.matchingTypeReferenceString = "";
			    super.replacementTypeReferenceString = "";
			    super.targetTypeReferenceString = "";
			    super.definitionTypeReferenceString = "";
			  }
			}
		''')
	}
	
	@Test
	def void compileSchemeWithTypeRefStrings(){
		'''
			package test;
			
			class refactoring test()
				int a ; char b ;
				~~~~~~~~~~~~~~
				double c ; long d ; String e ;
			target
				public void f(boolean b) { }
			definition
				byte b ; short s ;
			
		'''
		.assertCompilesTo(
		'''
			package test;
			
			import hu.elte.refjava.api.ClassRefactoring;
			
			@SuppressWarnings("all")
			public class test extends ClassRefactoring {
			  public test() {
			    super("int a ; char b ;", "double c ; long d ; String e ;");
			  }
			  
			  protected void setMetaVariables() {
			    super.definitionString = "byte b ; short s ;";
			    
			    super.matchingTypeReferenceString = "int|char|";
			    super.replacementTypeReferenceString = "double|long|java.lang.String|";
			    super.targetTypeReferenceString = "void|boolean|";
			    super.definitionTypeReferenceString = "byte|short|";
			  }
			  
			  @Override
			  protected boolean safeTargetCheck() {
			    return super.targetCheck("public void f(boolean b) { }");
			  }
			}
		''')
	}
}