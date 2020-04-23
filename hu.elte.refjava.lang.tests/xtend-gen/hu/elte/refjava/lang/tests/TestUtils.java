package hu.elte.refjava.lang.tests;

import org.eclipse.jdt.core.dom.AST;
import org.eclipse.jdt.core.dom.ASTNode;
import org.eclipse.jdt.core.dom.ASTParser;
import org.eclipse.jdt.core.dom.CompilationUnit;

@SuppressWarnings("all")
public class TestUtils {
  public static CompilationUnit getCompliationUnit(final String str) {
    CompilationUnit _xblockexpression = null;
    {
      final ASTParser parser = ASTParser.newParser(AST.JLS12);
      parser.setResolveBindings(true);
      parser.setSource(str.toCharArray());
      ASTNode _createAST = parser.createAST(null);
      final CompilationUnit newCompUnit = ((CompilationUnit) _createAST);
      _xblockexpression = newCompUnit;
    }
    return _xblockexpression;
  }
}
