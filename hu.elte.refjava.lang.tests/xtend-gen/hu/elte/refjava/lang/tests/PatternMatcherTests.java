package hu.elte.refjava.lang.tests;

import hu.elte.refjava.api.patterns.PatternMatcher;
import hu.elte.refjava.api.patterns.PatternParser;
import hu.elte.refjava.lang.refJava.Pattern;
import hu.elte.refjava.lang.refJava.Visibility;
import hu.elte.refjava.lang.tests.RefJavaInjectorProvider;
import hu.elte.refjava.lang.tests.TestUtils;
import java.util.List;
import org.eclipse.jdt.core.dom.Block;
import org.eclipse.jdt.core.dom.CompilationUnit;
import org.eclipse.jdt.core.dom.Expression;
import org.eclipse.jdt.core.dom.MethodDeclaration;
import org.eclipse.jdt.core.dom.SingleVariableDeclaration;
import org.eclipse.jdt.core.dom.Type;
import org.eclipse.jdt.core.dom.TypeDeclaration;
import org.eclipse.xtext.testing.InjectWith;
import org.eclipse.xtext.testing.extensions.InjectionExtension;
import org.eclipse.xtext.xbase.lib.CollectionLiterals;
import org.eclipse.xtext.xbase.lib.IterableExtensions;
import org.junit.jupiter.api.Assertions;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;

@ExtendWith(InjectionExtension.class)
@InjectWith(RefJavaInjectorProvider.class)
@SuppressWarnings("all")
class PatternMatcherTests {
  private final PatternMatcher matcher = new PatternMatcher(null);
  
  private Pattern pattern;
  
  private CompilationUnit source;
  
  @Test
  public void variableDeclarationMatcherTest() {
    this.pattern = PatternParser.parse("type#T1 name#N1 ; type#T2 name#N2 ;");
    this.source = TestUtils.getCompliationUnit("class A { void f(){ int a; char b; } }");
    Object _head = IterableExtensions.<Object>head(this.source.types());
    Object _head_1 = IterableExtensions.<Object>head(((TypeDeclaration) _head).bodyDeclarations());
    final Block block = ((MethodDeclaration) _head_1).getBody();
    Assertions.assertTrue(this.matcher.match(this.pattern, block.statements(), CollectionLiterals.<String, String>newHashMap(), CollectionLiterals.<String, Type>newHashMap(), CollectionLiterals.<String, List<SingleVariableDeclaration>>newHashMap(), CollectionLiterals.<String, Visibility>newHashMap(), CollectionLiterals.<String, List<Expression>>newHashMap(), null));
  }
  
  @Test
  public void fieldDeclarationMatcherTest() {
    this.pattern = PatternParser.parse("visibility#V1 type#T1 name#N1 ; visibility#V2 type#T2 name#N2 ;");
    this.source = TestUtils.getCompliationUnit("class A { public int a ; private char b; } }");
    Object _head = IterableExtensions.<Object>head(this.source.types());
    final TypeDeclaration typeDecl = ((TypeDeclaration) _head);
    Assertions.assertTrue(this.matcher.match(this.pattern, typeDecl.bodyDeclarations(), CollectionLiterals.<String, String>newHashMap(), CollectionLiterals.<String, Type>newHashMap(), CollectionLiterals.<String, List<SingleVariableDeclaration>>newHashMap(), CollectionLiterals.<String, Visibility>newHashMap(), CollectionLiterals.<String, List<Expression>>newHashMap(), null));
  }
  
  @Test
  public void methodDeclarationMatcherTest() {
    this.pattern = PatternParser.parse("visibility#V1 type#T1 name#N1() {} ; visibility#V2 type#T2 name#N2() {} ;");
    this.source = TestUtils.getCompliationUnit("class A { public void f() {} private int g() {} }");
    Object _head = IterableExtensions.<Object>head(this.source.types());
    final TypeDeclaration typeDecl = ((TypeDeclaration) _head);
    Assertions.assertTrue(this.matcher.match(this.pattern, typeDecl.bodyDeclarations(), CollectionLiterals.<String, String>newHashMap(), CollectionLiterals.<String, Type>newHashMap(), CollectionLiterals.<String, List<SingleVariableDeclaration>>newHashMap(), CollectionLiterals.<String, Visibility>newHashMap(), CollectionLiterals.<String, List<Expression>>newHashMap(), null));
  }
  
  @Test
  public void methodInvocationTest() {
    this.pattern = PatternParser.parse("new name#N1() { visibility#V1 type#T1 name#N2() {} }.name#N3()");
    this.source = TestUtils.getCompliationUnit("class A { public void f() { new F() { public void apply() {} }.apply(); } }");
    Object _head = IterableExtensions.<Object>head(this.source.types());
    Object _head_1 = IterableExtensions.<Object>head(((TypeDeclaration) _head).bodyDeclarations());
    final Block block = ((MethodDeclaration) _head_1).getBody();
    Assertions.assertTrue(this.matcher.match(this.pattern, block.statements(), CollectionLiterals.<String, String>newHashMap(), CollectionLiterals.<String, Type>newHashMap(), CollectionLiterals.<String, List<SingleVariableDeclaration>>newHashMap(), CollectionLiterals.<String, Visibility>newHashMap(), CollectionLiterals.<String, List<Expression>>newHashMap(), null));
  }
}
