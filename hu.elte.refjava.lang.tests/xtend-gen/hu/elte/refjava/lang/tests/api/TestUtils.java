package hu.elte.refjava.lang.tests.api;

import com.google.common.base.Objects;
import hu.elte.refjava.api.patterns.ASTBuilder;
import hu.elte.refjava.api.patterns.PatternMatcher;
import hu.elte.refjava.api.patterns.PatternParser;
import hu.elte.refjava.lang.refJava.Pattern;
import hu.elte.refjava.lang.refJava.Visibility;
import java.util.List;
import java.util.Map;
import org.eclipse.jdt.core.dom.AST;
import org.eclipse.jdt.core.dom.ASTNode;
import org.eclipse.jdt.core.dom.ASTParser;
import org.eclipse.jdt.core.dom.CompilationUnit;
import org.eclipse.jdt.core.dom.Expression;
import org.eclipse.jdt.core.dom.MethodDeclaration;
import org.eclipse.jdt.core.dom.SingleVariableDeclaration;
import org.eclipse.jdt.core.dom.Type;
import org.eclipse.jdt.core.dom.TypeDeclaration;
import org.eclipse.xtext.xbase.lib.IterableExtensions;
import org.junit.jupiter.api.Assertions;

@SuppressWarnings("all")
public class TestUtils {
  public static CompilationUnit getCompliationUnit(final String str) {
    CompilationUnit _xblockexpression = null;
    {
      final ASTParser parser = ASTParser.newParser(AST.JLS12);
      parser.setUnitName("test.java");
      parser.setEnvironment(null, null, null, true);
      parser.setResolveBindings(true);
      parser.setSource(str.toCharArray());
      ASTNode _createAST = parser.createAST(null);
      final CompilationUnit newCompUnit = ((CompilationUnit) _createAST);
      _xblockexpression = newCompUnit;
    }
    return _xblockexpression;
  }
  
  public static void testMatcher(final String patternString, final String sourceString, final String declarationSource, final Map<String, String> nameBindings, final Map<String, Type> typeBindings, final Map<String, List<SingleVariableDeclaration>> parameterBindings, final Map<String, Visibility> visibilityBindings, final Map<String, List<Expression>> argumentBindings, final String typeRefString) {
    final PatternMatcher matcher = new PatternMatcher(null);
    final Pattern pattern = PatternParser.parse(patternString);
    final CompilationUnit source = TestUtils.getCompliationUnit(sourceString);
    List _xifexpression = null;
    boolean _equals = Objects.equal(declarationSource, "block");
    if (_equals) {
      Object _head = IterableExtensions.<Object>head(source.types());
      Object _head_1 = IterableExtensions.<Object>head(((TypeDeclaration) _head).bodyDeclarations());
      _xifexpression = ((MethodDeclaration) _head_1).getBody().statements();
    } else {
      List _xifexpression_1 = null;
      boolean _equals_1 = Objects.equal(declarationSource, "class");
      if (_equals_1) {
        Object _head_2 = IterableExtensions.<Object>head(source.types());
        _xifexpression_1 = ((TypeDeclaration) _head_2).bodyDeclarations();
      }
      _xifexpression = _xifexpression_1;
    }
    final List matchings = _xifexpression;
    Assertions.assertTrue(matcher.match(pattern, matchings, nameBindings, typeBindings, parameterBindings, visibilityBindings, argumentBindings, typeRefString));
  }
  
  public static List<ASTNode> testBuilder(final String patternString, final Map<String, List<? extends ASTNode>> bindings, final Map<String, String> nameBindings, final Map<String, Type> typeBindings, final Map<String, List<SingleVariableDeclaration>> parameterBindings, final Map<String, Visibility> visibilityBindings, final Map<String, List<Expression>> argumentBindings, final String typeRefString) {
    List<ASTNode> _xblockexpression = null;
    {
      final ASTBuilder builder = new ASTBuilder(null);
      final Pattern pattern = PatternParser.parse(patternString);
      final CompilationUnit source = TestUtils.getCompliationUnit("");
      _xblockexpression = builder.build(pattern, source.getAST(), bindings, nameBindings, typeBindings, parameterBindings, visibilityBindings, argumentBindings, typeRefString);
    }
    return _xblockexpression;
  }
}
