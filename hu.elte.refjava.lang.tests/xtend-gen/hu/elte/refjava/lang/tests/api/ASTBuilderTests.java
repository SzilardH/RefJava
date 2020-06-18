package hu.elte.refjava.lang.tests.api;

import hu.elte.refjava.lang.refJava.Visibility;
import hu.elte.refjava.lang.tests.RefJavaInjectorProvider;
import hu.elte.refjava.lang.tests.api.TestUtils;
import java.util.List;
import java.util.Map;
import org.eclipse.jdt.core.dom.ASTNode;
import org.eclipse.jdt.core.dom.CompilationUnit;
import org.eclipse.jdt.core.dom.Expression;
import org.eclipse.jdt.core.dom.ExpressionStatement;
import org.eclipse.jdt.core.dom.FieldDeclaration;
import org.eclipse.jdt.core.dom.MethodDeclaration;
import org.eclipse.jdt.core.dom.MethodInvocation;
import org.eclipse.jdt.core.dom.SingleVariableDeclaration;
import org.eclipse.jdt.core.dom.Type;
import org.eclipse.jdt.core.dom.TypeDeclaration;
import org.eclipse.jdt.core.dom.VariableDeclarationStatement;
import org.eclipse.xtend2.lib.StringConcatenation;
import org.eclipse.xtext.testing.InjectWith;
import org.eclipse.xtext.testing.extensions.InjectionExtension;
import org.eclipse.xtext.xbase.lib.CollectionLiterals;
import org.eclipse.xtext.xbase.lib.Functions.Function1;
import org.eclipse.xtext.xbase.lib.IterableExtensions;
import org.eclipse.xtext.xbase.lib.ListExtensions;
import org.junit.jupiter.api.Assertions;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;

@ExtendWith(InjectionExtension.class)
@InjectWith(RefJavaInjectorProvider.class)
@SuppressWarnings("all")
class ASTBuilderTests {
  private Map<String, List<? extends ASTNode>> bindings = CollectionLiterals.<String, List<? extends ASTNode>>newHashMap();
  
  private Map<String, String> nameBindings = CollectionLiterals.<String, String>newHashMap();
  
  private Map<String, Type> typeBindings = CollectionLiterals.<String, Type>newHashMap();
  
  private Map<String, List<SingleVariableDeclaration>> parameterBindings = CollectionLiterals.<String, List<SingleVariableDeclaration>>newHashMap();
  
  private Map<String, Visibility> visibilityBindings = CollectionLiterals.<String, Visibility>newHashMap();
  
  private Map<String, List<Expression>> argumentBindings = CollectionLiterals.<String, List<Expression>>newHashMap();
  
  private String typeRefString = null;
  
  private List<ASTNode> replacement;
  
  private CompilationUnit source;
  
  @Test
  public void variableDeclarationBuilderTest() {
    StringConcatenation _builder = new StringConcatenation();
    _builder.append("class A { public void f() { int a; char b; String str; } }");
    this.source = TestUtils.getCompliationUnit(_builder.toString());
    Object _head = IterableExtensions.<Object>head(this.source.types());
    Object _head_1 = IterableExtensions.<Object>head(((TypeDeclaration) _head).bodyDeclarations());
    final Function1<Object, VariableDeclarationStatement> _function = (Object it) -> {
      return ((VariableDeclarationStatement) it);
    };
    final List<VariableDeclarationStatement> sourceVariableDeclarations = ListExtensions.<Object, VariableDeclarationStatement>map(((MethodDeclaration) _head_1).getBody().statements(), _function);
    List<VariableDeclarationStatement> replacementVariableDeclarations = null;
    this.typeRefString = "void|int|char|java.lang.String|";
    StringConcatenation _builder_1 = new StringConcatenation();
    _builder_1.append("public void f() { int a ; char b ; String str }");
    this.replacement = TestUtils.testBuilder(_builder_1.toString(), 
      this.bindings, this.nameBindings, this.typeBindings, this.parameterBindings, this.visibilityBindings, this.argumentBindings, this.typeRefString);
    ASTNode _head_2 = IterableExtensions.<ASTNode>head(this.replacement);
    Assertions.assertTrue((_head_2 instanceof MethodDeclaration));
    ASTNode _head_3 = IterableExtensions.<ASTNode>head(this.replacement);
    replacementVariableDeclarations = ((MethodDeclaration) _head_3).getBody().statements();
    for (int i = 0; (i < replacementVariableDeclarations.size()); i++) {
      {
        VariableDeclarationStatement _get = replacementVariableDeclarations.get(i);
        Assertions.assertTrue((_get instanceof VariableDeclarationStatement));
        Assertions.assertEquals(replacementVariableDeclarations.get(i).toString(), sourceVariableDeclarations.get(i).toString());
      }
    }
    this.typeRefString = "void|";
    this.nameBindings.put("N1", "a");
    this.nameBindings.put("N2", "b");
    this.nameBindings.put("N3", "str");
    this.typeBindings.put("T1", sourceVariableDeclarations.get(0).getType());
    this.typeBindings.put("T2", sourceVariableDeclarations.get(1).getType());
    this.typeBindings.put("T3", sourceVariableDeclarations.get(2).getType());
    StringConcatenation _builder_2 = new StringConcatenation();
    _builder_2.append("public void f() { type#T1 name#N1 ; type#T2 name#N2 ; type#T3 name#N3 }");
    this.replacement = TestUtils.testBuilder(_builder_2.toString(), 
      this.bindings, this.nameBindings, this.typeBindings, this.parameterBindings, this.visibilityBindings, this.argumentBindings, this.typeRefString);
    ASTNode _head_4 = IterableExtensions.<ASTNode>head(this.replacement);
    Assertions.assertTrue((_head_4 instanceof MethodDeclaration));
    ASTNode _head_5 = IterableExtensions.<ASTNode>head(this.replacement);
    replacementVariableDeclarations = ((MethodDeclaration) _head_5).getBody().statements();
    for (int i = 0; (i < replacementVariableDeclarations.size()); i++) {
      {
        VariableDeclarationStatement _get = replacementVariableDeclarations.get(i);
        Assertions.assertTrue((_get instanceof VariableDeclarationStatement));
        Assertions.assertEquals(sourceVariableDeclarations.get(i).toString(), replacementVariableDeclarations.get(i).toString());
      }
    }
  }
  
  @Test
  public void fieldDeclarationBuilderTest() {
    StringConcatenation _builder = new StringConcatenation();
    _builder.append("class A { public int a; private char b; String str }");
    this.source = TestUtils.getCompliationUnit(_builder.toString());
    Object _head = IterableExtensions.<Object>head(this.source.types());
    final Function1<Object, FieldDeclaration> _function = (Object it) -> {
      return ((FieldDeclaration) it);
    };
    final List<FieldDeclaration> sourceFieldDeclarations = ListExtensions.<Object, FieldDeclaration>map(((TypeDeclaration) _head).bodyDeclarations(), _function);
    List<FieldDeclaration> replacementFieldDeclarations = null;
    this.typeRefString = "int|char|java.lang.String|";
    StringConcatenation _builder_1 = new StringConcatenation();
    _builder_1.append("public int a ; private char b ; String str");
    this.replacement = TestUtils.testBuilder(_builder_1.toString(), 
      this.bindings, this.nameBindings, this.typeBindings, this.parameterBindings, this.visibilityBindings, this.argumentBindings, this.typeRefString);
    final Function1<ASTNode, Boolean> _function_1 = (ASTNode it) -> {
      return Boolean.valueOf((it instanceof FieldDeclaration));
    };
    Assertions.assertTrue(IterableExtensions.<ASTNode>forall(this.replacement, _function_1));
    final Function1<ASTNode, FieldDeclaration> _function_2 = (ASTNode it) -> {
      return ((FieldDeclaration) it);
    };
    replacementFieldDeclarations = ListExtensions.<ASTNode, FieldDeclaration>map(this.replacement, _function_2);
    for (int i = 0; (i < replacementFieldDeclarations.size()); i++) {
      Assertions.assertEquals(sourceFieldDeclarations.get(i).toString(), replacementFieldDeclarations.get(i).toString());
    }
    this.typeRefString = null;
    this.nameBindings.put("N1", "a");
    this.nameBindings.put("N2", "b");
    this.nameBindings.put("N3", "str");
    this.typeBindings.put("T1", sourceFieldDeclarations.get(0).getType());
    this.typeBindings.put("T2", sourceFieldDeclarations.get(1).getType());
    this.typeBindings.put("T3", sourceFieldDeclarations.get(2).getType());
    this.visibilityBindings.put("V1", Visibility.PUBLIC);
    this.visibilityBindings.put("V2", Visibility.PRIVATE);
    this.visibilityBindings.put("V3", Visibility.PACKAGE);
    StringConcatenation _builder_2 = new StringConcatenation();
    _builder_2.append("visibility#V1 type#T1 name#N1 ; visibility#V2 type#T2 name#N2 ; visibility#V3 type#T3 name#N3");
    this.replacement = TestUtils.testBuilder(_builder_2.toString(), 
      this.bindings, this.nameBindings, this.typeBindings, this.parameterBindings, this.visibilityBindings, this.argumentBindings, this.typeRefString);
    final Function1<ASTNode, Boolean> _function_3 = (ASTNode it) -> {
      return Boolean.valueOf((it instanceof FieldDeclaration));
    };
    Assertions.assertTrue(IterableExtensions.<ASTNode>forall(this.replacement, _function_3));
    final Function1<ASTNode, FieldDeclaration> _function_4 = (ASTNode it) -> {
      return ((FieldDeclaration) it);
    };
    replacementFieldDeclarations = ListExtensions.<ASTNode, FieldDeclaration>map(this.replacement, _function_4);
    for (int i = 0; (i < replacementFieldDeclarations.size()); i++) {
      Assertions.assertEquals(sourceFieldDeclarations.get(i).toString(), replacementFieldDeclarations.get(i).toString());
    }
  }
  
  @Test
  public void methodDeclarationBuilderTest() {
    StringConcatenation _builder = new StringConcatenation();
    _builder.append("class A { public void f(int a){ } private short g(boolean l, char b){ } String h(){ } }");
    this.source = TestUtils.getCompliationUnit(_builder.toString());
    Object _head = IterableExtensions.<Object>head(this.source.types());
    final Function1<Object, MethodDeclaration> _function = (Object it) -> {
      return ((MethodDeclaration) it);
    };
    final List<MethodDeclaration> sourceMethodDeclarations = ListExtensions.<Object, MethodDeclaration>map(((TypeDeclaration) _head).bodyDeclarations(), _function);
    List<MethodDeclaration> replacementMethodDeclarations = null;
    this.typeRefString = "void|int|short|boolean|char|java.lang.String|";
    StringConcatenation _builder_1 = new StringConcatenation();
    _builder_1.append("public void f(int a){ } ; private short g(boolean l, char b){ } ; String h(){ }");
    this.replacement = TestUtils.testBuilder(_builder_1.toString(), 
      this.bindings, this.nameBindings, this.typeBindings, this.parameterBindings, this.visibilityBindings, this.argumentBindings, this.typeRefString);
    final Function1<ASTNode, Boolean> _function_1 = (ASTNode it) -> {
      return Boolean.valueOf((it instanceof MethodDeclaration));
    };
    Assertions.assertTrue(IterableExtensions.<ASTNode>forall(this.replacement, _function_1));
    final Function1<ASTNode, MethodDeclaration> _function_2 = (ASTNode it) -> {
      return ((MethodDeclaration) it);
    };
    replacementMethodDeclarations = ListExtensions.<ASTNode, MethodDeclaration>map(this.replacement, _function_2);
    for (int i = 0; (i < replacementMethodDeclarations.size()); i++) {
      Assertions.assertEquals(sourceMethodDeclarations.get(i).toString(), replacementMethodDeclarations.get(i).toString());
    }
    this.typeRefString = null;
    this.nameBindings.put("N1", "f");
    this.nameBindings.put("N2", "g");
    this.nameBindings.put("N3", "h");
    this.typeBindings.put("T1", sourceMethodDeclarations.get(0).getReturnType2());
    this.typeBindings.put("T2", sourceMethodDeclarations.get(1).getReturnType2());
    this.typeBindings.put("T3", sourceMethodDeclarations.get(2).getReturnType2());
    this.visibilityBindings.put("V1", Visibility.PUBLIC);
    this.visibilityBindings.put("V2", Visibility.PRIVATE);
    this.visibilityBindings.put("V3", Visibility.PACKAGE);
    this.parameterBindings.put("P1", sourceMethodDeclarations.get(0).parameters());
    this.parameterBindings.put("P2", sourceMethodDeclarations.get(1).parameters());
    this.parameterBindings.put("P3", sourceMethodDeclarations.get(2).parameters());
    StringConcatenation _builder_2 = new StringConcatenation();
    _builder_2.append("visibility#V1 type#T1 name#N1(parameter#P1..){ } ; visibility#V2 type#T2 name#N2(parameter#P2..){ } ; visibility#V3 type#T3 name#N3(parameter#P3..){ }");
    this.replacement = TestUtils.testBuilder(_builder_2.toString(), 
      this.bindings, this.nameBindings, this.typeBindings, this.parameterBindings, this.visibilityBindings, this.argumentBindings, this.typeRefString);
    final Function1<ASTNode, Boolean> _function_3 = (ASTNode it) -> {
      return Boolean.valueOf((it instanceof MethodDeclaration));
    };
    Assertions.assertTrue(IterableExtensions.<ASTNode>forall(this.replacement, _function_3));
    final Function1<ASTNode, MethodDeclaration> _function_4 = (ASTNode it) -> {
      return ((MethodDeclaration) it);
    };
    replacementMethodDeclarations = ListExtensions.<ASTNode, MethodDeclaration>map(this.replacement, _function_4);
    for (int i = 0; (i < replacementMethodDeclarations.size()); i++) {
      Assertions.assertEquals(sourceMethodDeclarations.get(i).toString(), replacementMethodDeclarations.get(i).toString());
    }
  }
  
  @Test
  public void methodInvocetionAndConstructorCallBuilderTest() {
    StringConcatenation _builder = new StringConcatenation();
    _builder.append("class A { public void f() { new F() { public void apply(int a, char b) {} }.apply(a, b); new G() { public void apply() {} }.apply(); } int a = 1; char b = \'a\'; }");
    this.source = TestUtils.getCompliationUnit(_builder.toString());
    Object _head = IterableExtensions.<Object>head(this.source.types());
    Object _head_1 = IterableExtensions.<Object>head(((TypeDeclaration) _head).bodyDeclarations());
    final Function1<Object, MethodInvocation> _function = (Object it) -> {
      Expression _expression = ((ExpressionStatement) it).getExpression();
      return ((MethodInvocation) _expression);
    };
    final List<MethodInvocation> sourceMethodInvocations = ListExtensions.<Object, MethodInvocation>map(((MethodDeclaration) _head_1).getBody().statements(), _function);
    List<MethodInvocation> replacementMethodInvocations = null;
    this.typeRefString = "void|int|char|void|";
    this.argumentBindings.put("A1", sourceMethodInvocations.get(0).arguments());
    StringConcatenation _builder_1 = new StringConcatenation();
    _builder_1.append("new F() { public void apply(int a, char b) {} }.apply(argument#A1..) ; new G() { public void apply() {} }.apply()");
    this.replacement = TestUtils.testBuilder(_builder_1.toString(), 
      this.bindings, this.nameBindings, this.typeBindings, this.parameterBindings, this.visibilityBindings, this.argumentBindings, this.typeRefString);
    Assertions.assertTrue((IterableExtensions.<ASTNode>forall(this.replacement, ((Function1<ASTNode, Boolean>) (ASTNode it) -> {
      return Boolean.valueOf((it instanceof ExpressionStatement));
    })) && IterableExtensions.<ASTNode>forall(this.replacement, ((Function1<ASTNode, Boolean>) (ASTNode it) -> {
      Expression _expression = ((ExpressionStatement) it).getExpression();
      return Boolean.valueOf((_expression instanceof MethodInvocation));
    }))));
    final Function1<ASTNode, MethodInvocation> _function_1 = (ASTNode it) -> {
      Expression _expression = ((ExpressionStatement) it).getExpression();
      return ((MethodInvocation) _expression);
    };
    replacementMethodInvocations = ListExtensions.<ASTNode, MethodInvocation>map(this.replacement, _function_1);
    for (int i = 0; (i < replacementMethodInvocations.size()); i++) {
      Assertions.assertEquals(sourceMethodInvocations.get(i).toString(), replacementMethodInvocations.get(i).toString());
    }
    this.nameBindings.put("N1", "F");
    this.nameBindings.put("N2", "G");
    StringConcatenation _builder_2 = new StringConcatenation();
    _builder_2.append("new name#N1() { public void apply(int a, char b) {} }.apply(argument#A1..) ; new name#N2() { public void apply() {} }.apply()");
    this.replacement = TestUtils.testBuilder(_builder_2.toString(), 
      this.bindings, this.nameBindings, this.typeBindings, this.parameterBindings, this.visibilityBindings, this.argumentBindings, this.typeRefString);
    Assertions.assertTrue((IterableExtensions.<ASTNode>forall(this.replacement, ((Function1<ASTNode, Boolean>) (ASTNode it) -> {
      return Boolean.valueOf((it instanceof ExpressionStatement));
    })) && IterableExtensions.<ASTNode>forall(this.replacement, ((Function1<ASTNode, Boolean>) (ASTNode it) -> {
      Expression _expression = ((ExpressionStatement) it).getExpression();
      return Boolean.valueOf((_expression instanceof MethodInvocation));
    }))));
    final Function1<ASTNode, MethodInvocation> _function_2 = (ASTNode it) -> {
      Expression _expression = ((ExpressionStatement) it).getExpression();
      return ((MethodInvocation) _expression);
    };
    replacementMethodInvocations = ListExtensions.<ASTNode, MethodInvocation>map(this.replacement, _function_2);
    for (int i = 0; (i < replacementMethodInvocations.size()); i++) {
      Assertions.assertEquals(sourceMethodInvocations.get(i).toString(), replacementMethodInvocations.get(i).toString());
    }
  }
}
