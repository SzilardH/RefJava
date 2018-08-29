package hu.elte.refjava.control.handlers

import hu.elte.refjava.control.wizards.RefJavaWizard
import org.eclipse.core.commands.AbstractHandler
import org.eclipse.core.commands.ExecutionEvent
import org.eclipse.core.commands.ExecutionException
import org.eclipse.jface.wizard.WizardDialog

class RefJavaHandler extends AbstractHandler {

	override execute(ExecutionEvent event) throws ExecutionException {
		val wizard = new RefJavaWizard
		val wizardDialog = new WizardDialog(null, wizard)

		wizard.dialog = wizardDialog
		wizardDialog.open

		return null;
	}

}
