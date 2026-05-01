"""
Prompt Manager for NotebookLM Flashcard Generator.
Allows users to add, edit, and delete prompt templates through a GUI.
"""

import json
import os
from pathlib import Path
from aqt.qt import (
    QDialog, QVBoxLayout, QHBoxLayout, QListWidget, QListWidgetItem,
    QPushButton, QTextEdit, QLineEdit, QLabel, QMessageBox, Qt,
)
from aqt.utils import showInfo


PROMPTS_FILE = Path(__file__).parent / "user_prompts.json"


def load_prompts(default_prompts: dict) -> dict:
    """Load prompts from user file, falling back to defaults."""
    if PROMPTS_FILE.exists():
        try:
            with open(PROMPTS_FILE, 'r') as f:
                user_prompts = json.load(f)
                # Merge: user prompts override defaults
                return {**default_prompts, **user_prompts}
        except Exception:
            pass
    return default_prompts.copy()


def save_prompts(prompts: dict, default_keys: list) -> None:
    """Save only user-added prompts to file."""
    # Only save prompts that aren't in defaults
    user_only = {k: v for k, v in prompts.items() if k not in default_keys}
    with open(PROMPTS_FILE, 'w') as f:
        json.dump(user_only, f, indent=2)


class PromptManagerDialog(QDialog):
    """Dialog for managing prompt templates."""
    
    def __init__(self, prompts: dict, default_keys: list, parent=None):
        super().__init__(parent)
        self.prompts = prompts.copy()
        self.default_keys = default_keys
        self.current_key = None
        
        self.setWindowTitle("Manage Prompt Templates")
        self.setMinimumWidth(600)
        self.setMinimumHeight(500)
        
        self._build_ui()
        self._populate_list()
    
    def _build_ui(self):
        layout = QVBoxLayout(self)
        
        # Prompt list
        list_layout = QHBoxLayout()
        self.list_widget = QListWidget()
        self.list_widget.currentItemChanged.connect(self._on_select_prompt)
        list_layout.addWidget(self.list_widget)
        
        # Buttons for list
        btn_layout = QVBoxLayout()
        self.add_btn = QPushButton("Add New")
        self.add_btn.clicked.connect(self._on_add)
        self.edit_btn = QPushButton("Edit")
        self.edit_btn.clicked.connect(self._on_edit)
        self.delete_btn = QPushButton("Delete")
        self.delete_btn.clicked.connect(self._on_delete)
        btn_layout.addWidget(self.add_btn)
        btn_layout.addWidget(self.edit_btn)
        btn_layout.addWidget(self.delete_btn)
        btn_layout.addStretch()
        list_layout.addLayout(btn_layout)
        layout.addLayout(list_layout)
        
        # Editor area
        layout.addWidget(QLabel("Prompt Name:"))
        self.name_input = QLineEdit()
        self.name_input.textChanged.connect(self._on_name_changed)
        layout.addWidget(self.name_input)
        
        layout.addWidget(QLabel("Prompt Text:"))
        self.text_edit = QTextEdit()
        self.text_edit.setPlaceholderText(
            "Enter your prompt here...\n\n"
            "IMPORTANT: Your prompt must instruct NotebookLM to return ONLY a valid JSON array "
            "with 'Front' and 'Back' keys.\n\n"
            "Example: Return ONLY a valid JSON array of objects with 'Front' and 'Back' keys. "
            "Generate as many flashcards as possible."
        )
        layout.addWidget(self.text_edit)
        
        # Save/Cancel buttons
        button_layout = QHBoxLayout()
        self.save_btn = QPushButton("Save Prompt")
        self.save_btn.clicked.connect(self._on_save)
        self.cancel_btn = QPushButton("Cancel")
        self.cancel_btn.clicked.connect(self.reject)
        button_layout.addWidget(self.save_btn)
        button_layout.addWidget(self.cancel_btn)
        layout.addLayout(button_layout)
    
    def _populate_list(self):
        self.list_widget.clear()
        for name in sorted(self.prompts.keys()):
            item = QListWidgetItem(name)
            # Mark default prompts
            if name in self.default_keys:
                item.setText(f"{name} (Default)")
                item.setFlags(item.flags() & ~Qt.ItemFlag.ItemIsEnabled)  # Disable deletion
            self.list_widget.addItem(item)
    
    def _on_select_prompt(self, current, previous):
        if not current:
            return
        name = current.text().replace(" (Default)", "")
        self.current_key = name
        self.name_input.setText(name)
        self.text_edit.setText(self.prompts.get(name, ""))
        # Disable editing for defaults
        is_default = name in self.default_keys
        self.text_edit.setReadOnly(is_default)
        self.name_input.setReadOnly(is_default)
        self.delete_btn.setEnabled(not is_default)
    
    def _on_add(self):
        self.current_key = None
        self.name_input.clear()
        self.text_edit.clear()
        self.name_input.setReadOnly(False)
        self.text_edit.setReadOnly(False)
        self.delete_btn.setEnabled(True)
    
    def _on_edit(self):
        if self.current_key and self.current_key not in self.default_keys:
            self.name_input.setReadOnly(False)
            self.text_edit.setReadOnly(False)
    
    def _on_delete(self):
        if self.current_key and self.current_key not in self.default_keys:
            reply = QMessageBox.question(
                self, "Confirm Delete",
                f"Delete prompt '{self.current_key}'?",
                QMessageBox.StandardButton.Yes | QMessageBox.StandardButton.No
            )
            if reply == QMessageBox.StandardButton.Yes:
                del self.prompts[self.current_key]
                self._populate_list()
                self.name_input.clear()
                self.text_edit.clear()
    
    def _on_name_changed(self, text):
        # Prevent empty names
        self.save_btn.setEnabled(bool(text.strip()))
    
    def _on_save(self):
        name = self.name_input.text().strip()
        text = self.text_edit.toPlainText().strip()
        
        if not name:
            QMessageBox.warning(self, "Error", "Prompt name cannot be empty.")
            return
        if not text:
            QMessageBox.warning(self, "Error", "Prompt text cannot be empty.")
            return
        
        self.prompts[name] = text
        self.current_key = name
        self._populate_list()
        
        # Save to file
        save_prompts(self.prompts, self.default_keys)
        
        QMessageBox.information(self, "Saved", f"Prompt '{name}' saved successfully!")
    
    def get_prompts(self) -> dict:
        return self.prompts
