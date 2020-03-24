package hu.elte.refjava.control.wizards

import hu.elte.refjava.api.Refactoring
import org.eclipse.core.resources.ResourcesPlugin
import org.eclipse.jdt.core.IPackageFragment
import org.eclipse.jdt.core.JavaCore
import org.eclipse.jdt.core.dom.AST
import org.eclipse.jdt.core.dom.ASTParser
import org.eclipse.jdt.core.dom.CompilationUnit
import org.eclipse.jdt.core.dom.ITypeBinding
import org.eclipse.jdt.core.dom.TypeDeclaration
import org.eclipse.jface.wizard.WizardPage
import org.eclipse.swt.SWT
import org.eclipse.swt.widgets.Composite
import org.eclipse.swt.widgets.Event
import org.eclipse.swt.widgets.List
import org.eclipse.swt.widgets.Listener
import org.eclipse.xtext.ui.XtextProjectHelper

class RefJavaWizardPage extends WizardPage {

	public static val String TITLE = "RefJava Refactoring"
	public static val String DESCRIPTION = "Select a RefJava refactoring to apply"

	List schemeInstanceListView
	java.util.List<ITypeBinding> schemeInstanceList

	new() {
		super("RefJavaWizardPage")
		setTitle(TITLE)
		setDescription(DESCRIPTION)
	}

	def getSelectedRefactoringRule() {
		schemeInstanceList.get(schemeInstanceListView.selectionIndex)
	}

	override createControl(Composite parent) {
		schemeInstanceList = ResourcesPlugin.workspace.root.projects
			.filter[open && hasNature(JavaCore.NATURE_ID) && hasNature(XtextProjectHelper.NATURE_ID)]
			.map[JavaCore.create(it)]
			.map[it -> rawClasspath]
			.flatMap[e | e.value.map[e.key.findPackageFragmentRoots(it).toList].flatten]
			.flatMap[children.toList]
			.map[it as IPackageFragment]
			.flatMap[compilationUnits.toList]
			.map [
				// do not optimize
				val parser = ASTParser.newParser(AST.JLS12)
				parser.setResolveBindings(true)
				parser.source = it
				parser.createAST(null) as CompilationUnit
			].flatMap[types]
			.map[it as TypeDeclaration]
			.map[resolveBinding]
			.filter [
				var currentClass = it
				while (currentClass !== null) {
					if (currentClass.interfaces.exists[qualifiedName == Refactoring.name]) {
						return true
					}
					currentClass = currentClass.superclass
				}
				return false
			].toList

		schemeInstanceListView = new List(parent, SWT.V_SCROLL)
		schemeInstanceList.forEach[schemeInstanceListView.add(qualifiedName)]
		schemeInstanceListView.addListener(SWT.MouseDoubleClick, new Listener() {
			override handleEvent(Event event) {
				val wizard = RefJavaWizardPage.this.wizard as RefJavaWizard
				wizard.performFinish
				wizard.dialog.close
			}
		})

		setControl(schemeInstanceListView)
	}

}
