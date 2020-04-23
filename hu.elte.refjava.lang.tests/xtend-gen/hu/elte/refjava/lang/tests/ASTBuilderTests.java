package hu.elte.refjava.lang.tests;

import hu.elte.refjava.api.patterns.ASTBuilder;
import hu.elte.refjava.api.patterns.PatternParser;
import hu.elte.refjava.lang.refJava.PExpression;
import hu.elte.refjava.lang.refJava.PVariableDeclaration;
import hu.elte.refjava.lang.refJava.Pattern;
import hu.elte.refjava.lang.refJava.Visibility;
import hu.elte.refjava.lang.tests.RefJavaInjectorProvider;
import hu.elte.refjava.lang.tests.TestUtils;
import java.util.List;
import org.eclipse.jdt.core.dom.ASTNode;
import org.eclipse.jdt.core.dom.CompilationUnit;
import org.eclipse.jdt.core.dom.Expression;
import org.eclipse.jdt.core.dom.FieldDeclaration;
import org.eclipse.jdt.core.dom.MethodDeclaration;
import org.eclipse.jdt.core.dom.SingleVariableDeclaration;
import org.eclipse.jdt.core.dom.Type;
import org.eclipse.jdt.core.dom.TypeDeclaration;
import org.eclipse.jdt.core.dom.VariableDeclarationFragment;
import org.eclipse.jdt.core.dom.VariableDeclarationStatement;
import org.eclipse.xtext.testing.InjectWith;
import org.eclipse.xtext.testing.extensions.InjectionExtension;
import org.eclipse.xtext.xbase.lib.CollectionLiterals;
import org.eclipse.xtext.xbase.lib.Functions.Function1;
import org.eclipse.xtext.xbase.lib.IterableExtensions;
import org.junit.jupiter.api.Assertions;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;

@ExtendWith(InjectionExtension.class)
@InjectWith(RefJavaInjectorProvider.class)
@SuppressWarnings("all")
class ASTBuilderTests {
  private final ASTBuilder builder = new ASTBuilder(null);
  
  private Pattern pattern;
  
  private CompilationUnit source;
  
  private String typeRefString;
  
  private List<ASTNode> replacement;
  
  @Test
  public void variableDeclarationBuilderTest() {
    this.pattern = PatternParser.parse("public void f() { int a ; char b ; }");
    this.source = TestUtils.getCompliationUnit("class A { void f(){ int a; char b; } }");
    this.typeRefString = "void|int|char|";
    this.replacement = this.builder.build(this.pattern, this.source.getAST(), CollectionLiterals.<String, List<? extends ASTNode>>newHashMap(), CollectionLiterals.<String, String>newHashMap(), CollectionLiterals.<String, Type>newHashMap(), CollectionLiterals.<String, List<SingleVariableDeclaration>>newHashMap(), CollectionLiterals.<String, Visibility>newHashMap(), CollectionLiterals.<String, List<Expression>>newHashMap(), this.typeRefString);
    Object _head = IterableExtensions.<Object>head(this.source.types());
    Object _head_1 = IterableExtensions.<Object>head(((TypeDeclaration) _head).bodyDeclarations());
    final List variableDeclarations = ((MethodDeclaration) _head_1).getBody().statements();
    ASTNode _head_2 = IterableExtensions.<ASTNode>head(this.replacement);
    final Function1<Object, Boolean> _function = new Function1<Object, Boolean>() {
      public Boolean apply(final Object it) {
        return Boolean.valueOf((it instanceof VariableDeclarationStatement));
      }
    };
    Assertions.assertTrue(IterableExtensions.<Object>forall(((MethodDeclaration) _head_2).getBody().statements(), _function));
    PExpression _head_3 = IterableExtensions.<PExpression>head(this.pattern.getPatterns());
    ASTNode _head_4 = IterableExtensions.<ASTNode>head(this.replacement);
    Object _head_5 = IterableExtensions.<Object>head(((MethodDeclaration) _head_4).getBody().statements());
    Object _head_6 = IterableExtensions.<Object>head(((VariableDeclarationStatement) _head_5).fragments());
    Assertions.assertEquals(((PVariableDeclaration) _head_3).getName(), ((VariableDeclarationFragment) _head_6).getName().getIdentifier());
    PExpression _last = IterableExtensions.<PExpression>last(this.pattern.getPatterns());
    ASTNode _head_7 = IterableExtensions.<ASTNode>head(this.replacement);
    Object _last_1 = IterableExtensions.<Object>last(((MethodDeclaration) _head_7).getBody().statements());
    Object _head_8 = IterableExtensions.<Object>head(((VariableDeclarationStatement) _last_1).fragments());
    Assertions.assertEquals(((PVariableDeclaration) _last).getName(), ((VariableDeclarationFragment) _head_8).getName().getIdentifier());
    Object _head_9 = IterableExtensions.<Object>head(variableDeclarations);
    ASTNode _head_10 = IterableExtensions.<ASTNode>head(this.replacement);
    Object _head_11 = IterableExtensions.<Object>head(((MethodDeclaration) _head_10).getBody().statements());
    Assertions.assertEquals(((VariableDeclarationStatement) _head_9).getType().toString(), ((VariableDeclarationStatement) _head_11).getType().toString());
    Object _last_2 = IterableExtensions.<Object>last(variableDeclarations);
    ASTNode _head_12 = IterableExtensions.<ASTNode>head(this.replacement);
    Object _last_3 = IterableExtensions.<Object>last(((MethodDeclaration) _head_12).getBody().statements());
    Assertions.assertEquals(((VariableDeclarationStatement) _last_2).getType().toString(), ((VariableDeclarationStatement) _last_3).getType().toString());
  }
  
  @Test
  public void fieldDeclarationBuilderTest() {
    this.pattern = PatternParser.parse("int a; char b;");
    this.source = TestUtils.getCompliationUnit("class A { public int a; private char b; }");
    this.typeRefString = "int|char|";
    this.replacement = this.builder.build(this.pattern, this.source.getAST(), CollectionLiterals.<String, List<? extends ASTNode>>newHashMap(), CollectionLiterals.<String, String>newHashMap(), CollectionLiterals.<String, Type>newHashMap(), CollectionLiterals.<String, List<SingleVariableDeclaration>>newHashMap(), CollectionLiterals.<String, Visibility>newHashMap(), CollectionLiterals.<String, List<Expression>>newHashMap(), this.typeRefString);
    Object _head = IterableExtensions.<Object>head(this.source.types());
    final List fieldDeclarations = ((TypeDeclaration) _head).bodyDeclarations();
    final Function1<ASTNode, Boolean> _function = new Function1<ASTNode, Boolean>() {
      public Boolean apply(final ASTNode it) {
        return Boolean.valueOf((it instanceof FieldDeclaration));
      }
    };
    Assertions.assertTrue(IterableExtensions.<ASTNode>forall(this.replacement, _function));
    PExpression _head_1 = IterableExtensions.<PExpression>head(this.pattern.getPatterns());
    ASTNode _head_2 = IterableExtensions.<ASTNode>head(this.replacement);
    Object _head_3 = IterableExtensions.<Object>head(((FieldDeclaration) _head_2).fragments());
    Assertions.assertEquals(((PVariableDeclaration) _head_1).getName(), 
      ((VariableDeclarationFragment) _head_3).getName().getIdentifier());
    PExpression _last = IterableExtensions.<PExpression>last(this.pattern.getPatterns());
    ASTNode _last_1 = IterableExtensions.<ASTNode>last(this.replacement);
    Object _head_4 = IterableExtensions.<Object>head(((FieldDeclaration) _last_1).fragments());
    Assertions.assertEquals(((PVariableDeclaration) _last).getName(), 
      ((VariableDeclarationFragment) _head_4).getName().getIdentifier());
    Object _head_5 = IterableExtensions.<Object>head(fieldDeclarations);
    ASTNode _head_6 = IterableExtensions.<ASTNode>head(this.replacement);
    Assertions.assertEquals(((FieldDeclaration) _head_5).getType().toString(), ((FieldDeclaration) _head_6).getType().toString());
    Object _last_2 = IterableExtensions.<Object>last(fieldDeclarations);
    ASTNode _last_3 = IterableExtensions.<ASTNode>last(this.replacement);
    Assertions.assertEquals(((FieldDeclaration) _last_2).getType().toString(), ((FieldDeclaration) _last_3).getType().toString());
  }
  
  @Test
  public void methodDeclarationBuilderTest() {
    Assertions.<Object>fail("not implemented");
  }
  
  @Test
  public void constructorCallBuilderTest() {
    Assertions.<Object>fail("not implemented");
  }
  
  @Test
  public void methodInvocationBuilderTest() {
    Assertions.<Object>fail("not implemented");
  }
}
