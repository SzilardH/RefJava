package hu.elte.refjava.control.wizards

import hu.elte.refjava.api.Refactoring
import hu.elte.refjava.control.utils.SelectionNodeFinder
import hu.elte.refjava.control.utils.TypeDeclarationGetter
import java.net.URLClassLoader
import org.eclipse.jdt.core.ICompilationUnit
import org.eclipse.jdt.core.dom.AST
import org.eclipse.jdt.core.dom.ASTParser
import org.eclipse.jdt.core.dom.CompilationUnit
import org.eclipse.jdt.ui.JavaUI
import org.eclipse.jface.dialogs.MessageDialog
import org.eclipse.jface.text.TextSelection
import org.eclipse.jface.wizard.Wizard
import org.eclipse.jface.wizard.WizardDialog
import org.eclipse.ui.PlatformUI
import org.eclipse.ui.texteditor.ITextEditor

class RefJavaWizard extends Wizard {

	RefJavaWizardPage page = new RefJavaWizardPage
	WizardDialog dialog

	override getWindowTitle() {
		"RefJava Refactoring"
	}

	override void addPages() {
		super.addPages();
		addPage(page);
	}

	override performFinish() {
		val refactoringRule = page.selectedRefactoringRule
		val refactoringElement = refactoringRule.javaElement

		val url = refactoringElement.resource.project.location.append(
			refactoringElement.javaProject.outputLocation.lastSegment).toFile.toURI.toURL
		val urlClassLoader = new URLClassLoader(#[url], class.classLoader)

		val refactoringClass = urlClassLoader.loadClass(refactoringRule.qualifiedName)
		val refactoringInstance = refactoringClass.constructors.head.newInstance as Refactoring

		val editor = PlatformUI.workbench.activeWorkbenchWindow.activePage.activeEditor
		if (editor instanceof ITextEditor) {
			
			val selection = editor.selectionProvider.selection
			if (selection instanceof TextSelection) {
				
				val allTypeDeclarationInWorkSpace = TypeDeclarationGetter.allTypeDeclarationInWorkspace
				
				val typeRoot = JavaUI.getEditorInputTypeRoot(editor.editorInput)
				val iCompUnit = typeRoot.getAdapter(ICompilationUnit)

				val parser = ASTParser.newParser(AST.JLS12)
				parser.setResolveBindings(true)
				parser.source = iCompUnit
				val compUnit = parser.createAST(null) as CompilationUnit
				
				val selectedNodes = SelectionNodeFinder.selectedNodes(selection, compUnit)
				
				val provider = editor.documentProvider
				val document = provider.getDocument(editor.editorInput)
				
				refactoringInstance.init(selectedNodes, document, allTypeDeclarationInWorkSpace)
				val status = refactoringInstance.apply				
				switch status {
					case SUCCESS:
						MessageDialog.openInformation(dialog.shell, "Success",
							"The selected refactoring has been successfully applied.")
					default:
						MessageDialog.openError(dialog.shell, "Failure",
							"The selected refactoring could not been applied. Reason: " + status.toString + ".")
				}
			}
		}
		return true;
	}

	def setDialog(WizardDialog dialog) {
		this.dialog = dialog
	}

	def getDialog() {
		dialog
	}

}
