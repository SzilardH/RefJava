package hu.elte.refjava.lang.tests.api;

import hu.elte.refjava.lang.refJava.Visibility;
import hu.elte.refjava.lang.tests.RefJavaInjectorProvider;
import hu.elte.refjava.lang.tests.api.TestUtils;
import java.util.List;
import java.util.Map;
import org.eclipse.jdt.core.dom.ClassInstanceCreation;
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
import org.eclipse.xtext.xbase.lib.IterableExtensions;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;

@ExtendWith(InjectionExtension.class)
@InjectWith(RefJavaInjectorProvider.class)
@SuppressWarnings("all")
class PatternMatcherTests {
  private Map<String, String> nameBindings = CollectionLiterals.<String, String>newHashMap();
  
  private Map<String, Type> typeBindings = CollectionLiterals.<String, Type>newHashMap();
  
  private Map<String, List<SingleVariableDeclaration>> parameterBindings = CollectionLiterals.<String, List<SingleVariableDeclaration>>newHashMap();
  
  private Map<String, Visibility> visibilityBindings = CollectionLiterals.<String, Visibility>newHashMap();
  
  private Map<String, List<Expression>> argumentBindings = CollectionLiterals.<String, List<Expression>>newHashMap();
  
  private String typeRefString = null;
  
  @Test
  public void variableDeclarationMatcherTest() {
    StringConcatenation _builder = new StringConcatenation();
    _builder.append("type#T1 name#N1 ; type#T2 name#N2 ;");
    StringConcatenation _builder_1 = new StringConcatenation();
    _builder_1.append("class A {");
    _builder_1.newLine();
    _builder_1.append("\t");
    _builder_1.append("void f(){");
    _builder_1.newLine();
    _builder_1.append("\t\t");
    _builder_1.append("int a;");
    _builder_1.newLine();
    _builder_1.append("\t\t");
    _builder_1.append("char b;");
    _builder_1.newLine();
    _builder_1.append("\t");
    _builder_1.append("}");
    _builder_1.newLine();
    _builder_1.append("}");
    _builder_1.newLine();
    TestUtils.testMatcher(_builder.toString(), _builder_1.toString(), 
      "block", 
      this.nameBindings, this.typeBindings, this.parameterBindings, this.visibilityBindings, this.argumentBindings, this.typeRefString);
    final CompilationUnit compUnit = TestUtils.getCompliationUnit("class A { void f(){ int a; char b; } }");
    Object _head = IterableExtensions.<Object>head(compUnit.types());
    Object _head_1 = IterableExtensions.<Object>head(((TypeDeclaration) _head).bodyDeclarations());
    final List methodBody = ((MethodDeclaration) _head_1).getBody().statements();
    this.nameBindings.put("N1", "a");
    this.nameBindings.put("N2", "b");
    Object _head_2 = IterableExtensions.<Object>head(methodBody);
    this.typeBindings.put("T1", ((VariableDeclarationStatement) _head_2).getType());
    Object _last = IterableExtensions.<Object>last(methodBody);
    this.typeBindings.put("T2", ((VariableDeclarationStatement) _last).getType());
    StringConcatenation _builder_2 = new StringConcatenation();
    _builder_2.append("type#T1 name#N1 ; type#T2 name#N2 ;");
    StringConcatenation _builder_3 = new StringConcatenation();
    _builder_3.append("class A {");
    _builder_3.newLine();
    _builder_3.append("\t");
    _builder_3.append("void f(){");
    _builder_3.newLine();
    _builder_3.append("\t\t");
    _builder_3.append("int a;");
    _builder_3.newLine();
    _builder_3.append("\t\t");
    _builder_3.append("char b;");
    _builder_3.newLine();
    _builder_3.append("\t");
    _builder_3.append("}");
    _builder_3.newLine();
    _builder_3.append("}");
    _builder_3.newLine();
    TestUtils.testMatcher(_builder_2.toString(), _builder_3.toString(), 
      "block", 
      this.nameBindings, this.typeBindings, this.parameterBindings, this.visibilityBindings, this.argumentBindings, this.typeRefString);
    this.typeRefString = "int|char|java.lang.String|";
    StringConcatenation _builder_4 = new StringConcatenation();
    _builder_4.append("int a ; char b ; String c ;");
    StringConcatenation _builder_5 = new StringConcatenation();
    _builder_5.append("class A {");
    _builder_5.newLine();
    _builder_5.append("\t");
    _builder_5.append("void f(){");
    _builder_5.newLine();
    _builder_5.append("\t\t");
    _builder_5.append("int a;");
    _builder_5.newLine();
    _builder_5.append("\t\t");
    _builder_5.append("char b;");
    _builder_5.newLine();
    _builder_5.append("\t\t");
    _builder_5.append("String c;");
    _builder_5.newLine();
    _builder_5.append("\t");
    _builder_5.append("}");
    _builder_5.newLine();
    _builder_5.append("}");
    _builder_5.newLine();
    TestUtils.testMatcher(_builder_4.toString(), _builder_5.toString(), 
      "block", 
      this.nameBindings, this.typeBindings, this.parameterBindings, this.visibilityBindings, this.argumentBindings, this.typeRefString);
  }
  
  @Test
  public void fieldDeclarationMatcherTest() {
    StringConcatenation _builder = new StringConcatenation();
    _builder.append("visibility#V1 type#T1 name#N1 ; visibility#V2 type#T2 name#N2 ;");
    StringConcatenation _builder_1 = new StringConcatenation();
    _builder_1.append("class A {");
    _builder_1.newLine();
    _builder_1.append("\t");
    _builder_1.append("public int a;");
    _builder_1.newLine();
    _builder_1.append("\t");
    _builder_1.append("private char b;");
    _builder_1.newLine();
    _builder_1.append("}");
    _builder_1.newLine();
    TestUtils.testMatcher(_builder.toString(), _builder_1.toString(), 
      "class", 
      this.nameBindings, this.typeBindings, this.parameterBindings, this.visibilityBindings, this.argumentBindings, this.typeRefString);
    final CompilationUnit compUnit = TestUtils.getCompliationUnit("class A { public int a; private char b; }");
    Object _head = IterableExtensions.<Object>head(compUnit.types());
    final List fieldDeclarations = ((TypeDeclaration) _head).bodyDeclarations();
    this.nameBindings.put("N1", "a");
    this.nameBindings.put("N2", "b");
    Object _head_1 = IterableExtensions.<Object>head(fieldDeclarations);
    this.typeBindings.put("T1", ((FieldDeclaration) _head_1).getType());
    Object _last = IterableExtensions.<Object>last(fieldDeclarations);
    this.typeBindings.put("T2", ((FieldDeclaration) _last).getType());
    this.visibilityBindings.put("V1", Visibility.PUBLIC);
    this.visibilityBindings.put("V2", Visibility.PRIVATE);
    StringConcatenation _builder_2 = new StringConcatenation();
    _builder_2.append("visibility#V1 type#T1 name#N1 ; visibility#V2 type#T2 name#N2 ;");
    StringConcatenation _builder_3 = new StringConcatenation();
    _builder_3.append("class A {");
    _builder_3.newLine();
    _builder_3.append("\t");
    _builder_3.append("public int a ;");
    _builder_3.newLine();
    _builder_3.append("\t");
    _builder_3.append("private char b;");
    _builder_3.newLine();
    _builder_3.append("}");
    _builder_3.newLine();
    TestUtils.testMatcher(_builder_2.toString(), _builder_3.toString(), 
      "class", 
      this.nameBindings, this.typeBindings, this.parameterBindings, this.visibilityBindings, this.argumentBindings, this.typeRefString);
    this.typeRefString = "int|char|";
    StringConcatenation _builder_4 = new StringConcatenation();
    _builder_4.append("public int a ; private char b ;");
    StringConcatenation _builder_5 = new StringConcatenation();
    _builder_5.append("class A {");
    _builder_5.newLine();
    _builder_5.append("\t");
    _builder_5.append("public int a ;");
    _builder_5.newLine();
    _builder_5.append("\t");
    _builder_5.append("private char b;");
    _builder_5.newLine();
    _builder_5.append("}");
    _builder_5.newLine();
    TestUtils.testMatcher(_builder_4.toString(), _builder_5.toString(), 
      "class", 
      this.nameBindings, this.typeBindings, this.parameterBindings, this.visibilityBindings, this.argumentBindings, this.typeRefString);
  }
  
  @Test
  public void methodDeclarationMatcherTest() {
    StringConcatenation _builder = new StringConcatenation();
    _builder.append("visibility#V1 type#T1 name#N1(parameter#P1..) {} ; visibility#V2 type#T2 name#N2(parameter#P2..) {} ;");
    StringConcatenation _builder_1 = new StringConcatenation();
    _builder_1.append("class A { ");
    _builder_1.newLine();
    _builder_1.append("\t");
    _builder_1.append("public void f(int a, String str) {} ");
    _builder_1.newLine();
    _builder_1.append("\t");
    _builder_1.append("private int g() {}");
    _builder_1.newLine();
    _builder_1.append("}");
    _builder_1.newLine();
    TestUtils.testMatcher(_builder.toString(), _builder_1.toString(), 
      "class", 
      this.nameBindings, this.typeBindings, this.parameterBindings, this.visibilityBindings, this.argumentBindings, this.typeRefString);
    final CompilationUnit compUnit = TestUtils.getCompliationUnit("class A { public void f(int a, String str) {} private int g() {} }");
    Object _head = IterableExtensions.<Object>head(compUnit.types());
    final List methodDeclarations = ((TypeDeclaration) _head).bodyDeclarations();
    this.nameBindings.put("N1", "f");
    this.nameBindings.put("N2", "g");
    Object _head_1 = IterableExtensions.<Object>head(methodDeclarations);
    this.typeBindings.put("T1", ((MethodDeclaration) _head_1).getReturnType2());
    Object _last = IterableExtensions.<Object>last(methodDeclarations);
    this.typeBindings.put("T2", ((MethodDeclaration) _last).getReturnType2());
    this.visibilityBindings.put("V1", Visibility.PUBLIC);
    this.visibilityBindings.put("V2", Visibility.PRIVATE);
    Object _head_2 = IterableExtensions.<Object>head(methodDeclarations);
    this.parameterBindings.put("P1", ((MethodDeclaration) _head_2).parameters());
    Object _last_1 = IterableExtensions.<Object>last(methodDeclarations);
    this.parameterBindings.put("P2", ((MethodDeclaration) _last_1).parameters());
    StringConcatenation _builder_2 = new StringConcatenation();
    _builder_2.append("visibility#V1 type#T1 name#N1(parameter#P1..) {} ; visibility#V2 type#T2 name#N2(parameter#P2..) {} ;");
    StringConcatenation _builder_3 = new StringConcatenation();
    _builder_3.append("class A { ");
    _builder_3.newLine();
    _builder_3.append("\t");
    _builder_3.append("public void f(int a, String str) {}");
    _builder_3.newLine();
    _builder_3.append("\t");
    _builder_3.append("private int g() {}");
    _builder_3.newLine();
    _builder_3.append("}");
    _builder_3.newLine();
    TestUtils.testMatcher(_builder_2.toString(), _builder_3.toString(), 
      "class", 
      this.nameBindings, this.typeBindings, this.parameterBindings, this.visibilityBindings, this.argumentBindings, this.typeRefString);
    this.typeRefString = "void|int|java.lang.String|int|";
    StringConcatenation _builder_4 = new StringConcatenation();
    _builder_4.append("public void f(int a, String str) {} ; private int g() {} ;");
    StringConcatenation _builder_5 = new StringConcatenation();
    _builder_5.append("class A { ");
    _builder_5.newLine();
    _builder_5.append("\t");
    _builder_5.append("public void f(int a, String str) {}");
    _builder_5.newLine();
    _builder_5.append("\t");
    _builder_5.append("private int g() {}");
    _builder_5.newLine();
    _builder_5.append("}");
    _builder_5.newLine();
    TestUtils.testMatcher(_builder_4.toString(), _builder_5.toString(), 
      "class", 
      this.nameBindings, this.typeBindings, this.parameterBindings, this.visibilityBindings, this.argumentBindings, this.typeRefString);
  }
  
  @Test
  public void methodInvocationAndConstructorCallMatcherTest() {
    StringConcatenation _builder = new StringConcatenation();
    _builder.append("new name#N1() { visibility#V1 type#T1 name#N2(parameter#P1..) {} }.name#N2(argument#A1..)");
    StringConcatenation _builder_1 = new StringConcatenation();
    _builder_1.append("class A {");
    _builder_1.newLine();
    _builder_1.append("\t");
    _builder_1.append("void f() {");
    _builder_1.newLine();
    _builder_1.append("\t\t");
    _builder_1.append("new F() {");
    _builder_1.newLine();
    _builder_1.append("\t\t\t");
    _builder_1.append("public void apply(int a) {}");
    _builder_1.newLine();
    _builder_1.append("\t\t");
    _builder_1.append("}.apply(a);");
    _builder_1.newLine();
    _builder_1.append("\t");
    _builder_1.append("}");
    _builder_1.newLine();
    _builder_1.append("\t");
    _builder_1.append("public int a = 1;");
    _builder_1.newLine();
    _builder_1.append("}");
    _builder_1.newLine();
    TestUtils.testMatcher(_builder.toString(), _builder_1.toString(), 
      "block", 
      this.nameBindings, this.typeBindings, this.parameterBindings, this.visibilityBindings, this.argumentBindings, this.typeRefString);
    final CompilationUnit compUnit = TestUtils.getCompliationUnit("class A { public void f() { new F() { public void apply(int a, char b) {} }.apply(a, b); } int a = 1; char b = \'a\'; }");
    Object _head = IterableExtensions.<Object>head(compUnit.types());
    Object _head_1 = IterableExtensions.<Object>head(((TypeDeclaration) _head).bodyDeclarations());
    Object _head_2 = IterableExtensions.<Object>head(((MethodDeclaration) _head_1).getBody().statements());
    Expression _expression = ((ExpressionStatement) _head_2).getExpression();
    final MethodInvocation methodInvocation = ((MethodInvocation) _expression);
    Object _head_3 = IterableExtensions.<Object>head(compUnit.types());
    Object _head_4 = IterableExtensions.<Object>head(((TypeDeclaration) _head_3).bodyDeclarations());
    Object _head_5 = IterableExtensions.<Object>head(((MethodDeclaration) _head_4).getBody().statements());
    Expression _expression_1 = ((ExpressionStatement) _head_5).getExpression();
    Expression _expression_2 = ((MethodInvocation) _expression_1).getExpression();
    Object _head_6 = IterableExtensions.<Object>head(((ClassInstanceCreation) _expression_2).getAnonymousClassDeclaration().bodyDeclarations());
    final MethodDeclaration method = ((MethodDeclaration) _head_6);
    this.nameBindings.put("N1", "F");
    this.nameBindings.put("N2", "apply");
    this.typeBindings.put("T1", method.getReturnType2());
    this.visibilityBindings.put("V1", Visibility.PUBLIC);
    this.parameterBindings.put("P1", method.parameters());
    this.argumentBindings.put("A1", methodInvocation.arguments());
    StringConcatenation _builder_2 = new StringConcatenation();
    _builder_2.append("new name#N1() { visibility#V1 type#T1 name#N2(parameter#P1..) {} }.name#N2(argument#A1..)");
    StringConcatenation _builder_3 = new StringConcatenation();
    _builder_3.append("class A {");
    _builder_3.newLine();
    _builder_3.append("\t");
    _builder_3.append("void f() {");
    _builder_3.newLine();
    _builder_3.append("\t\t");
    _builder_3.append("new F() {");
    _builder_3.newLine();
    _builder_3.append("\t\t\t");
    _builder_3.append("public void apply(int a, char b) {}");
    _builder_3.newLine();
    _builder_3.append("\t\t");
    _builder_3.append("}.apply(a, b);");
    _builder_3.newLine();
    _builder_3.append("\t");
    _builder_3.append("}");
    _builder_3.newLine();
    _builder_3.append("\t");
    _builder_3.append("int a = 1;");
    _builder_3.newLine();
    _builder_3.append("\t");
    _builder_3.append("char b = \'a\';");
    _builder_3.newLine();
    _builder_3.append("}");
    _builder_3.newLine();
    TestUtils.testMatcher(_builder_2.toString(), _builder_3.toString(), 
      "block", 
      this.nameBindings, this.typeBindings, this.parameterBindings, this.visibilityBindings, this.argumentBindings, this.typeRefString);
    this.typeRefString = "void|int|char|";
    StringConcatenation _builder_4 = new StringConcatenation();
    _builder_4.append("new F() { public void apply(int a, char b) {} }.apply(argument#A1..)");
    StringConcatenation _builder_5 = new StringConcatenation();
    _builder_5.append("class A {");
    _builder_5.newLine();
    _builder_5.append("\t");
    _builder_5.append("void f() {");
    _builder_5.newLine();
    _builder_5.append("\t\t");
    _builder_5.append("new F() {");
    _builder_5.newLine();
    _builder_5.append("\t\t\t");
    _builder_5.append("public void apply(int a, char b) {}");
    _builder_5.newLine();
    _builder_5.append("\t\t");
    _builder_5.append("}.apply(a, b);");
    _builder_5.newLine();
    _builder_5.append("\t");
    _builder_5.append("}");
    _builder_5.newLine();
    _builder_5.append("}");
    _builder_5.newLine();
    _builder_5.append("int a = 1;");
    _builder_5.newLine();
    _builder_5.append("char b = \'a\';");
    _builder_5.newLine();
    TestUtils.testMatcher(_builder_4.toString(), _builder_5.toString(), 
      "block", 
      this.nameBindings, this.typeBindings, this.parameterBindings, this.visibilityBindings, this.argumentBindings, this.typeRefString);
  }
}
