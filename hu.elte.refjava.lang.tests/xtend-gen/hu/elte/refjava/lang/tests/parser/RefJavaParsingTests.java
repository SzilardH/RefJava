package hu.elte.refjava.lang.tests.parser;

import com.google.inject.Inject;
import hu.elte.refjava.lang.refJava.AssignmentList;
import hu.elte.refjava.lang.refJava.File;
import hu.elte.refjava.lang.refJava.MetaVariableType;
import hu.elte.refjava.lang.refJava.PBlockExpression;
import hu.elte.refjava.lang.refJava.PConstructorCall;
import hu.elte.refjava.lang.refJava.PExpression;
import hu.elte.refjava.lang.refJava.PFeatureCall;
import hu.elte.refjava.lang.refJava.PMemberFeatureCall;
import hu.elte.refjava.lang.refJava.PMetaVariable;
import hu.elte.refjava.lang.refJava.PMethodDeclaration;
import hu.elte.refjava.lang.refJava.PNothingExpression;
import hu.elte.refjava.lang.refJava.PReturnExpression;
import hu.elte.refjava.lang.refJava.PTargetExpression;
import hu.elte.refjava.lang.refJava.PVariableDeclaration;
import hu.elte.refjava.lang.refJava.Pattern;
import hu.elte.refjava.lang.refJava.RefactoringRule;
import hu.elte.refjava.lang.refJava.SchemeInstanceRule;
import hu.elte.refjava.lang.refJava.SchemeType;
import hu.elte.refjava.lang.tests.RefJavaInjectorProvider;
import org.eclipse.emf.common.util.EList;
import org.eclipse.xtend2.lib.StringConcatenation;
import org.eclipse.xtext.testing.InjectWith;
import org.eclipse.xtext.testing.extensions.InjectionExtension;
import org.eclipse.xtext.testing.util.ParseHelper;
import org.eclipse.xtext.xbase.XExpression;
import org.eclipse.xtext.xbase.lib.Exceptions;
import org.eclipse.xtext.xbase.lib.Extension;
import org.eclipse.xtext.xbase.lib.Functions.Function1;
import org.eclipse.xtext.xbase.lib.IterableExtensions;
import org.junit.jupiter.api.Assertions;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;

@ExtendWith(InjectionExtension.class)
@InjectWith(RefJavaInjectorProvider.class)
@SuppressWarnings("all")
public class RefJavaParsingTests {
  @Inject
  @Extension
  private ParseHelper<File> parseHelper;
  
  @Test
  public void parseFile() {
    try {
      StringConcatenation _builder = new StringConcatenation();
      _builder.append("package file.test;");
      _builder.newLine();
      final File file = this.parseHelper.parse(_builder);
      Assertions.assertTrue((file instanceof File));
      Assertions.assertEquals(file.getName(), "file.test");
    } catch (Throwable _e) {
      throw Exceptions.sneakyThrow(_e);
    }
  }
  
  @Test
  public void parseAllSchemeTypes() {
    try {
      StringConcatenation _builder = new StringConcatenation();
      _builder.append("package file.test;");
      _builder.newLine();
      _builder.append("local refactoring localTest()");
      _builder.newLine();
      _builder.append("\t");
      _builder.append("nothing");
      _builder.newLine();
      _builder.append("\t");
      _builder.append("~~~~~~~");
      _builder.newLine();
      _builder.append("\t");
      _builder.append("nothing");
      _builder.newLine();
      _builder.append("\t");
      _builder.newLine();
      _builder.append("block refactoring blockTest()");
      _builder.newLine();
      _builder.append("\t");
      _builder.append("nothing");
      _builder.newLine();
      _builder.append("\t");
      _builder.append("~~~~~~~");
      _builder.newLine();
      _builder.append("\t");
      _builder.append("nothing");
      _builder.newLine();
      _builder.append("\t");
      _builder.newLine();
      _builder.append("lambda refactoring lambdaTest()");
      _builder.newLine();
      _builder.append("\t");
      _builder.append("nothing");
      _builder.newLine();
      _builder.append("\t");
      _builder.append("~~~~~~~");
      _builder.newLine();
      _builder.append("\t");
      _builder.append("nothing");
      _builder.newLine();
      _builder.append("\t");
      _builder.newLine();
      _builder.append("class refactoring classTest()");
      _builder.newLine();
      _builder.append("\t");
      _builder.append("nothing");
      _builder.newLine();
      _builder.append("\t");
      _builder.append("~~~~~~~");
      _builder.newLine();
      _builder.append("\t");
      _builder.append("nothing");
      _builder.newLine();
      final File file = this.parseHelper.parse(_builder);
      final Function1<RefactoringRule, Boolean> _function = (RefactoringRule it) -> {
        return Boolean.valueOf((it instanceof SchemeInstanceRule));
      };
      Assertions.assertTrue(IterableExtensions.<RefactoringRule>forall(file.getRefactorings(), _function));
      RefactoringRule _get = file.getRefactorings().get(0);
      Assertions.assertEquals(((SchemeInstanceRule) _get).getType(), SchemeType.LOCAL);
      RefactoringRule _get_1 = file.getRefactorings().get(0);
      Assertions.assertEquals(((SchemeInstanceRule) _get_1).getName(), "localTest");
      RefactoringRule _get_2 = file.getRefactorings().get(1);
      Assertions.assertEquals(((SchemeInstanceRule) _get_2).getType(), SchemeType.BLOCK);
      RefactoringRule _get_3 = file.getRefactorings().get(1);
      Assertions.assertEquals(((SchemeInstanceRule) _get_3).getName(), "blockTest");
      RefactoringRule _get_4 = file.getRefactorings().get(2);
      Assertions.assertEquals(((SchemeInstanceRule) _get_4).getType(), SchemeType.LAMBDA);
      RefactoringRule _get_5 = file.getRefactorings().get(2);
      Assertions.assertEquals(((SchemeInstanceRule) _get_5).getName(), "lambdaTest");
      RefactoringRule _get_6 = file.getRefactorings().get(3);
      Assertions.assertEquals(((SchemeInstanceRule) _get_6).getType(), SchemeType.CLASS);
      RefactoringRule _get_7 = file.getRefactorings().get(3);
      Assertions.assertEquals(((SchemeInstanceRule) _get_7).getName(), "classTest");
    } catch (Throwable _e) {
      throw Exceptions.sneakyThrow(_e);
    }
  }
  
  @Test
  public void parseSchemeProperties() {
    try {
      StringConcatenation _builder = new StringConcatenation();
      _builder.append("package file.test;");
      _builder.newLine();
      _builder.append("local refactoring test()");
      _builder.newLine();
      _builder.append("\t");
      _builder.append("nothing");
      _builder.newLine();
      _builder.append("\t");
      _builder.append("~~~~~~~");
      _builder.newLine();
      _builder.append("\t");
      _builder.append("nothing");
      _builder.newLine();
      _builder.append("target");
      _builder.newLine();
      _builder.append("\t");
      _builder.append("nothing");
      _builder.newLine();
      _builder.append("definition");
      _builder.newLine();
      _builder.append("\t");
      _builder.append("nothing");
      _builder.newLine();
      _builder.append("when");
      _builder.newLine();
      _builder.append("\t");
      _builder.append("assignment");
      _builder.newLine();
      _builder.append("\t\t");
      _builder.append("name#test  = \"TEST\"");
      _builder.newLine();
      _builder.append("\t");
      _builder.append("precondition");
      _builder.newLine();
      _builder.append("\t\t");
      _builder.append("true");
      _builder.newLine();
      final File file = this.parseHelper.parse(_builder);
      RefactoringRule _head = IterableExtensions.<RefactoringRule>head(file.getRefactorings());
      final SchemeInstanceRule refactoring = ((SchemeInstanceRule) _head);
      Pattern _matchingPattern = refactoring.getMatchingPattern();
      Assertions.assertTrue((_matchingPattern instanceof Pattern));
      Pattern _replacementPattern = refactoring.getReplacementPattern();
      Assertions.assertTrue((_replacementPattern instanceof Pattern));
      Pattern _targetPattern = refactoring.getTargetPattern();
      boolean _tripleEquals = (_targetPattern == null);
      Assertions.assertFalse(_tripleEquals);
      Pattern _targetPattern_1 = refactoring.getTargetPattern();
      Assertions.assertTrue((_targetPattern_1 instanceof Pattern));
      Pattern _definitionPattern = refactoring.getDefinitionPattern();
      boolean _tripleEquals_1 = (_definitionPattern == null);
      Assertions.assertFalse(_tripleEquals_1);
      Pattern _definitionPattern_1 = refactoring.getDefinitionPattern();
      Assertions.assertTrue((_definitionPattern_1 instanceof Pattern));
      AssignmentList _assignments = refactoring.getAssignments();
      boolean _tripleEquals_2 = (_assignments == null);
      Assertions.assertFalse(_tripleEquals_2);
      AssignmentList _assignments_1 = refactoring.getAssignments();
      Assertions.assertTrue((_assignments_1 instanceof AssignmentList));
      XExpression _precondition = refactoring.getPrecondition();
      boolean _tripleEquals_3 = (_precondition == null);
      Assertions.assertFalse(_tripleEquals_3);
      XExpression _precondition_1 = refactoring.getPrecondition();
      Assertions.assertTrue((_precondition_1 instanceof XExpression));
    } catch (Throwable _e) {
      throw Exceptions.sneakyThrow(_e);
    }
  }
  
  @Test
  public void parsePatternExpressions() {
    try {
      StringConcatenation _builder = new StringConcatenation();
      _builder.append("package file.test;");
      _builder.newLine();
      _builder.append("local refactoring test()");
      _builder.newLine();
      _builder.append("\t");
      _builder.append("#s ; target ; return ; nothing ; { } ; public int a ; public void f() { } ; method() ; A.method() ; new F() { }");
      _builder.newLine();
      _builder.append("\t");
      _builder.append("~~~~~~~");
      _builder.newLine();
      _builder.append("\t");
      _builder.append("nothing");
      _builder.newLine();
      final File file = this.parseHelper.parse(_builder);
      RefactoringRule _head = IterableExtensions.<RefactoringRule>head(file.getRefactorings());
      final Pattern pattern = ((SchemeInstanceRule) _head).getMatchingPattern();
      EList<PExpression> _patterns = pattern.getPatterns();
      boolean _tripleEquals = (_patterns == null);
      Assertions.assertFalse(_tripleEquals);
      final Function1<PExpression, Boolean> _function = (PExpression it) -> {
        return Boolean.valueOf((it instanceof PExpression));
      };
      Assertions.assertTrue(IterableExtensions.<PExpression>forall(pattern.getPatterns(), _function));
      final EList<PExpression> patterns = pattern.getPatterns();
      PExpression _get = patterns.get(0);
      Assertions.assertTrue((_get instanceof PMetaVariable));
      PExpression _get_1 = patterns.get(1);
      Assertions.assertTrue((_get_1 instanceof PTargetExpression));
      PExpression _get_2 = patterns.get(2);
      Assertions.assertTrue((_get_2 instanceof PReturnExpression));
      PExpression _get_3 = patterns.get(3);
      Assertions.assertTrue((_get_3 instanceof PNothingExpression));
      PExpression _get_4 = patterns.get(4);
      Assertions.assertTrue((_get_4 instanceof PBlockExpression));
      PExpression _get_5 = patterns.get(5);
      Assertions.assertTrue((_get_5 instanceof PVariableDeclaration));
      PExpression _get_6 = patterns.get(6);
      Assertions.assertTrue((_get_6 instanceof PMethodDeclaration));
      PExpression _get_7 = patterns.get(7);
      Assertions.assertTrue((_get_7 instanceof PFeatureCall));
      PExpression _get_8 = patterns.get(8);
      Assertions.assertTrue((_get_8 instanceof PMemberFeatureCall));
      PExpression _get_9 = patterns.get(9);
      Assertions.assertTrue((_get_9 instanceof PConstructorCall));
    } catch (Throwable _e) {
      throw Exceptions.sneakyThrow(_e);
    }
  }
  
  @Test
  public void parseMetaVariables() {
    try {
      StringConcatenation _builder = new StringConcatenation();
      _builder.append("package file.test;");
      _builder.newLine();
      _builder.append("local refactoring test()");
      _builder.newLine();
      _builder.append("\t");
      _builder.append("#s ; name#n ; type#t ; visibility#v ; argument#a.. ; parameter#p..");
      _builder.newLine();
      _builder.append("\t");
      _builder.append("~~~~~~~");
      _builder.newLine();
      _builder.append("\t");
      _builder.append("nothing");
      _builder.newLine();
      final File file = this.parseHelper.parse(_builder);
      RefactoringRule _head = IterableExtensions.<RefactoringRule>head(file.getRefactorings());
      final EList<PExpression> patterns = ((SchemeInstanceRule) _head).getMatchingPattern().getPatterns();
      final Function1<PExpression, Boolean> _function = (PExpression it) -> {
        return Boolean.valueOf((it instanceof PMetaVariable));
      };
      Assertions.assertTrue(IterableExtensions.<PExpression>forall(patterns, _function));
      PExpression _get = patterns.get(0);
      Assertions.assertEquals(((PMetaVariable) _get).getType(), MetaVariableType.CODE);
      PExpression _get_1 = patterns.get(1);
      Assertions.assertEquals(((PMetaVariable) _get_1).getType(), MetaVariableType.NAME);
      PExpression _get_2 = patterns.get(2);
      Assertions.assertEquals(((PMetaVariable) _get_2).getType(), MetaVariableType.TYPE);
      PExpression _get_3 = patterns.get(3);
      Assertions.assertEquals(((PMetaVariable) _get_3).getType(), MetaVariableType.VISIBILITY);
      PExpression _get_4 = patterns.get(4);
      Assertions.assertEquals(((PMetaVariable) _get_4).getType(), MetaVariableType.ARGUMENT);
      PExpression _get_5 = patterns.get(5);
      Assertions.assertEquals(((PMetaVariable) _get_5).getType(), MetaVariableType.PARAMETER);
    } catch (Throwable _e) {
      throw Exceptions.sneakyThrow(_e);
    }
  }
}
