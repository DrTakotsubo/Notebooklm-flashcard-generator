# =============================================================================
# NOTEBOOKLM FLASHCARD GENERATOR - CONFIGURATION BLOCK
# =============================================================================
# Edit the variables below to customize the behavior of the add-on.
# =============================================================================

# -----------------------------------------------------------------------------
# NOTEBOOKLM_PROMPTS
# -----------------------------------------------------------------------------
# Dictionary of prompts for flashcard generation. The key is the display name
# shown in the dropdown; the value is the prompt text.
# Each prompt MUST instruct NotebookLM to return ONLY a valid JSON array of
# objects with "Front" and "Back" keys.
# -----------------------------------------------------------------------------
NOTEBOOKLM_PROMPTS = {
    "NEET-PG: Macro/Micro (All Subjects)": """\
You are an expert medical tutor specializing in the Indian NEET-PG examination. Your task is to process the source document(s) and generate a highly structured set of flashcards based on the provided topic and PDF content.

Traverse the content systematically. Extract information using a two-tier "Macro" and "Micro" approach. Ensure strict adherence to the source text; do not hallucinate outside information.

For every distinct concept, disease, algorithm, table, or anatomical structure found in the text, generate flashcards using the following logic:

### 1. MACRO CARDS (Comprehensive Concepts)
Trigger: You encounter a complete management protocol, full classification table, multi-step pathophysiology, drug class overview, or major anatomical relationship.
Action: Create one comprehensive card that forces active recall of the entire concept.
- "Front": [Broad prompt, e.g., "Complete management algorithm for Diabetic Ketoacidosis?" or "Describe the branches of the External Carotid Artery."]
- "Back": [Bullet-point list summarizing the entire protocol/table/structure clearly and concisely.]

### 2. MICRO CARDS (High-Yield One-Liners)
Trigger: Within that same concept, identify the "volatile" high-yield facts—drug of choice (DOC), pathognomonic signs, most common causes (MCC), tumor markers, specific nerve supplies, or distinct laboratory findings.
Action: Create multiple short, punchy, single-fact flashcards for rapid-fire recall.
- "Front": [Specific trigger, e.g., "Most common cause of primary amenorrhea?"]
- "Back": [One-word or short phrase answer, e.g., "Turner Syndrome."]
- "Front": [Specific trigger, e.g., "Drug of choice for Trigeminal Neuralgia?"]
- "Back": [Carbamazepine.]

### OUTPUT FORMAT
Return ONLY a valid JSON array of objects. Do NOT include any explanation, markdown, or text outside the JSON. Each object MUST have exactly two keys: "Front" (string) and "Back" (string). Prefix the Front of each card with `[MACRO]` or `[MICRO]` accordingly.

Generate as many relevant, high-quality flashcards as possible from the source material, with no upper limit.

Example output:
[
  {"Front": "[MACRO] Complete management algorithm for Diabetic Ketoacidosis?", "Back": "• Fluid resuscitation: 0.9% NS\n• IV regular insulin bolus + infusion\n• Potassium replacement as needed\n• Monitor glucose every 1-2 hours"},
  {"Front": "[MICRO] Most common cause of primary amenorrhea?", "Back": "Turner Syndrome."},
  {"Front": "[MICRO] Drug of choice for Trigeminal Neuralgia?", "Back": "Carbamazepine."}
]
""",

    "NEET-PG: DOC, M/C, IOC, Genes": """\
You are an expert medical educator. Scan the uploaded source document and extract facts strictly fitting the criteria below for the provided topic. Extract ONLY facts matching these categories:

1. "Most common" (m/c, most frequent, most prevalent). Tag: m/c
2. "Investigation of Choice" (IOC, gold standard, best initial test). Tag: IOC
3. "Drug of Choice" (DOC, primary treatment). Tag: DOC
4. "Majority Percentages": Any complication, risk factor, or clinical association explicitly tied to a percentage greater than 50% (>50%). Convert into a "What is the most common..." question. Do NOT include the percentage in the answer. Tag: m/c. Ignore any stats 50% or lower.
5. "Radiological Findings": Characteristic imaging signs on X-ray, CT, MRI, or Ultrasound (e.g., specific appearances, shadows, named signs like "water bottle sign"). Tag: Radiology
6. "Histopathological Features": Classic biopsy findings, microscopic descriptions, named cells, or specific stains (e.g., "psammoma bodies", "caseating granuloma"). Tag: Histopathology
7. "Markers": Tumor, genetic, immunological, or biochemical markers associated with the disease (e.g., "CA 125", "HLA-B27", "p53 mutation"). Tag: Marker

### OUTPUT FORMAT
Return ONLY a valid JSON array of objects. Do NOT include any explanation, markdown, or text outside the JSON. Each object MUST have exactly two keys: "Front" (string) and "Back" (string). Prefix the Front with the tag in square brackets, e.g., `[DOC]`, `[m/c]`, `[IOC]`, `[Radiology]`, `[Histopathology]`, `[Marker]`.

Generate as many relevant, high-quality flashcards as possible from the source material, with no upper limit.

Example output:
[
  {"Front": "[DOC] Drug of choice for Trigeminal Neuralgia?", "Back": "Carbamazepine."},
  {"Front": "[m/c] Most common cause of primary amenorrhea?", "Back": "Turner Syndrome."},
  {"Front": "[IOC] Gold standard investigation for diagnosing pulmonary embolism?", "Back": "CT pulmonary angiography."},
  {"Front": "[Marker] Tumor marker for ovarian cancer?", "Back": "CA 125."}
]
""",

    "Medical Practical Exams (Verbatim)": """\
You are an expert medical assistant helping prepare for final year medical practical exams. Generate a comprehensive set of flashcards strictly from the uploaded source document for the provided topic.

CRITICAL RULE: Extract information EXACTLY as written in the source text. Do NOT alter, summarize, paraphrase, or simplify the language. Use verbatim text for all answers.

Generate flashcards following these rules:

1. Definitions: Create a flashcard for EVERY single definition related to the topic.
   - "Front": "Define [Term]."
   - "Back": [Verbatim definition.]

2. Clinical Gradings & Criteria: Extract grading systems (e.g., grades of murmurs, NYHA classification) or diagnostic criteria into ONE comprehensive card.
   - "Front": "What are the grades/criteria of [Clinical Sign/Condition]?"
   - "Back": [Full verbatim list.]

3. Causes / Etiologies: Group all causes into ONE card. Maintain exact categorization from the text (e.g., by anatomical location, pathophysiology, congenital vs. acquired).
   - "Front": "What are the causes of [Clinical Sign/Condition]?"
   - "Back": [List of causes, strictly organized by textbook categories.]

4. Clinical Features (Symptoms & Signs): Extract clinical presentations, grouping symptoms (history) and signs (examination findings) logically.
   - "Front": "What are the clinical features of [Topic]?"
   - "Back": [Verbatim list of symptoms and signs.]

5. Differential Diagnoses (DDx): Extract differentials. If the text distinguishes close differentials using specific clinical clues, include those distinguishing features.
   - "Front": "What are the differential diagnoses for [Topic]?"
   - "Back": [Verbatim list of DDx.]

6. Investigations: Group the diagnostic workup into ONE card. If categorized (e.g., Bedside, Bloods, Imaging, Gold Standard, Special Tests), maintain those exact categories.
   - "Front": "What are the investigations for [Topic]?"
   - "Back": [Categorized list of investigations.]

7. Management / Treatment: Extract treatment protocols. Maintain subdivisions (e.g., Acute vs. Chronic, Medical vs. Surgical, Conservative measures).
   - "Front": "What is the management for [Topic]?"
   - "Back": [Categorized verbatim management protocol.]

8. Complications: Extract stated complications related to disease progression or treatment.
   - "Front": "What are the complications of [Topic]?"
   - "Back": [Verbatim list of complications.]

9. Pathophysiology / Mechanisms: If the text explains the mechanism behind a sign (e.g., mechanism of an opening snap or specific pulse), extract it.
   - "Front": "What is the mechanism/pathophysiology of [Specific Sign/Condition]?"
   - "Back": [Verbatim textbook explanation.]

### OUTPUT FORMAT
Return ONLY a valid JSON array of objects. Do NOT include any explanation, markdown, or text outside the JSON. Each object MUST have exactly two keys: "Front" (string) and "Back" (string). The Front should follow the format "Define [Term].", "What are the causes of [Condition]?", etc.

Generate as many relevant, high-quality flashcards as possible from the source material, with no upper limit.

Example output:
[
  {"Front": "Define pallor.", "Back": "Pallor is a pale colour of the skin, mucous membranes, and nail beds, indicating reduced haemoglobin levels."},
  {"Front": "What are the clinical features of pallor?", "Back": "• Pale conjunctiva\n• Pale palmar creases\n• Pale oral mucosa\n• Fatigue and weakness"},
  {"Front": "What are the investigations for pallor?", "Back": "• Bedside: Complete blood count\n• Bloods: Serum ferritin, peripheral smear\n• Imaging: Ultrasound abdomen if splenomegaly suspected"}
]
""",
}

# Backwards compatibility: default prompt
NOTEBOOKLM_SYSTEM_PROMPT = list(NOTEBOOKLM_PROMPTS.values())[0]

# -----------------------------------------------------------------------------
# NOTEBOOKLM_NOTEBOOK_NAME
# -----------------------------------------------------------------------------
# Default name prefix for the NotebookLM notebook created during processing.
# -----------------------------------------------------------------------------
NOTEBOOKLM_NOTEBOOK_NAME = "Anki Flashcard Notebook"

# -----------------------------------------------------------------------------
# FLASHCARD_NOTE_TYPE
# -----------------------------------------------------------------------------
# The Anki note type to use for generated flashcards.
# Set to "Basic" for the default Anki note type, or create a custom one.
# -----------------------------------------------------------------------------
FLASHCARD_NOTE_TYPE = "Basic"

# -----------------------------------------------------------------------------
# ADDON_MENU_TEXT
# -----------------------------------------------------------------------------
# The text shown in Anki's Tools menu for this add-on.
# -----------------------------------------------------------------------------
ADDON_MENU_TEXT = "Import from NotebookLM..."

# =============================================================================
# END OF CONFIGURATION BLOCK
# =============================================================================


import os
import json

from aqt import mw
from aqt.qt import (
    QAction, QDialog, QVBoxLayout, QHBoxLayout, QLabel, QLineEdit,
    QPushButton, QFileDialog, QComboBox, QFormLayout, QTextEdit,
    QProgressBar, QThread, pyqtSignal, Qt,
)
from aqt.utils import showWarning, showInfo, tooltip

from . import notebooklm


# -----------------------------------------------------------------------------
# Worker thread for non-blocking flashcard generation
# -----------------------------------------------------------------------------

class NotebookLMWorker(QThread):
    """Background thread that handles the NotebookLM API calls."""

    progress = pyqtSignal(str)
    finished_success = pyqtSignal(list)
    finished_error = pyqtSignal(str)

    def __init__(self, topic, pdf_path, prompt):
        super().__init__()
        self.topic = topic
        self.pdf_path = pdf_path
        self.prompt = prompt

    def run(self):
        try:
            self.progress.emit("Uploading PDF to NotebookLM...")
            notebooklm.upload_pdf(self.pdf_path, self.topic)

            self.progress.emit("Generating flashcards...")
            flashcards_json = notebooklm.generate_flashcards(
                topic=self.topic,
                prompt=self.prompt,
            )

            self.progress.emit("Cleaning up NotebookLM notebook...")
            notebooklm.delete_notebook()

            self.finished_success.emit(flashcards_json)

        except Exception as e:
            # Try to clean up even on error
            try:
                notebooklm.delete_notebook()
            except Exception:
                pass
            self.finished_error.emit(str(e))


# -----------------------------------------------------------------------------
# Dialog
# -----------------------------------------------------------------------------

class NotebookLMDialog(QDialog):
    """Main dialog for the NotebookLM flashcard generator."""

    def __init__(self, parent=mw):
        super().__init__(parent)
        self.setWindowTitle("Import from NotebookLM")
        self.setMinimumWidth(500)
        self.setMinimumHeight(350)

        self._build_ui()
        self._populate_decks()
        self._populate_prompts()

    # -- UI construction ------------------------------------------------------

    def _build_ui(self):
        layout = QVBoxLayout(self)

        # Topic input
        topic_layout = QHBoxLayout()
        topic_label = QLabel("Topic:")
        topic_label.setMinimumWidth(80)
        self.topic_input = QLineEdit()
        self.topic_input.setPlaceholderText("e.g., Photosynthesis, World War II, Python Basics")
        topic_layout.addWidget(topic_label)
        topic_layout.addWidget(self.topic_input)

        # Prompt selector
        prompt_layout = QHBoxLayout()
        prompt_label = QLabel("Prompt:")
        prompt_label.setMinimumWidth(80)
        self.prompt_selector = QComboBox()
        prompt_layout.addWidget(prompt_label)
        prompt_layout.addWidget(self.prompt_selector)

        # Deck selector
        deck_layout = QHBoxLayout()
        deck_label = QLabel("Deck:")
        deck_label.setMinimumWidth(80)
        self.deck_selector = QComboBox()
        deck_layout.addWidget(deck_label)
        deck_layout.addWidget(self.deck_selector)

        # PDF file picker
        pdf_layout = QHBoxLayout()
        pdf_label = QLabel("PDF File:")
        pdf_label.setMinimumWidth(80)
        self.pdf_input = QLineEdit()
        self.pdf_input.setPlaceholderText("Select a PDF file...")
        self.pdf_input.setReadOnly(True)
        self.pdf_browse_btn = QPushButton("Browse...")
        self.pdf_browse_btn.clicked.connect(self._browse_pdf)
        pdf_layout.addWidget(pdf_label)
        pdf_layout.addWidget(self.pdf_input)
        pdf_layout.addWidget(self.pdf_browse_btn)

        # Progress area (hidden initially)
        self.progress_label = QLabel("")
        self.progress_label.setAlignment(Qt.AlignmentFlag.AlignCenter)
        self.progress_label.setStyleSheet("color: gray; font-style: italic;")
        self.progress_label.setVisible(False)

        # Generate button
        self.generate_btn = QPushButton("Generate Flashcards")
        self.generate_btn.setStyleSheet(
            "font-weight: bold; font-size: 14px; padding: 10px;"
        )
        self.generate_btn.clicked.connect(self._on_generate)

        # Assemble
        layout.addLayout(topic_layout)
        layout.addLayout(prompt_layout)
        layout.addLayout(deck_layout)
        layout.addLayout(pdf_layout)
        layout.addWidget(self.progress_label)
        layout.addWidget(self.generate_btn)

    # -- Deck population ------------------------------------------------------

    def _populate_decks(self):
        """Fill the deck dropdown with the user's actual Anki decks."""
        self.deck_selector.clear()
        deck_names = mw.col.decks.all_names()
        for name in sorted(deck_names):
            self.deck_selector.addItem(name)
        if self.deck_selector.count() == 0:
            self.deck_selector.addItem("Default")

    def _populate_prompts(self):
        """Fill the prompt dropdown with configured prompts."""
        self.prompt_selector.clear()
        for name in NOTEBOOKLM_PROMPTS:
            self.prompt_selector.addItem(name)

    # -- File browsing --------------------------------------------------------

    def _browse_pdf(self):
        # Default to user's home directory (cross-platform)
        default_dir = os.path.expanduser("~")
        if not os.path.isdir(default_dir):
            default_dir = ""

        path, _ = QFileDialog.getOpenFileName(
            self,
            "Select PDF File",
            default_dir,
            "PDF Files (*.pdf);;All Files (*)",
        )
        if path:
            self.pdf_input.setText(path)

    # -- Generate action ------------------------------------------------------

    def _on_generate(self):
        topic = self.topic_input.text().strip()
        pdf_path = self.pdf_input.text().strip()

        if not topic:
            showWarning("Please enter a topic for the flashcards.")
            return
        if not pdf_path or not os.path.exists(pdf_path):
            showWarning("Please select a valid PDF file.")
            return

        prompt_key = self.prompt_selector.currentText()
        prompt = NOTEBOOKLM_PROMPTS[prompt_key]

        self.generate_btn.setEnabled(False)
        self.generate_btn.setText("Generating...")
        self.progress_label.setVisible(True)
        self.progress_label.setText("Starting...")

        self.worker = NotebookLMWorker(topic, pdf_path, prompt)
        self.worker.progress.connect(self._on_progress)
        self.worker.finished_success.connect(self._on_success)
        self.worker.finished_error.connect(self._on_error)
        self.worker.start()

    def _on_progress(self, message):
        self.progress_label.setText(message)

    def _on_success(self, flashcards):
        self.generate_btn.setEnabled(True)
        self.generate_btn.setText("Generate Flashcards")
        self.progress_label.setVisible(False)

        count = self._add_flashcards_to_anki(flashcards)
        self.close()
        showInfo(
            f"Successfully added {count} flashcard(s) to Anki!",
            title="Import Complete",
        )
        mw.reset()

    def _on_error(self, error_message):
        self.generate_btn.setEnabled(True)
        self.generate_btn.setText("Generate Flashcards")
        self.progress_label.setVisible(False)
        showWarning(
            f"An error occurred during flashcard generation:\n\n{error_message}",
            title="Generation Failed",
        )

    # -- Anki note creation ---------------------------------------------------

    def _add_flashcards_to_anki(self, flashcards):
        """Parse the flashcard JSON and add Basic notes to the selected deck."""
        col = mw.col
        deck_name = self.deck_selector.currentText()
        deck_id = col.decks.id(deck_name)

        model = col.models.by_name(FLASHCARD_NOTE_TYPE)
        if not model:
            showWarning(
                f"Note type '{FLASHCARD_NOTE_TYPE}' not found in your Anki collection.\n"
                f"Please create it or change FLASHCARD_NOTE_TYPE in the add-on config.",
            )
            return 0

        added = 0
        for card in flashcards:
            front = card.get("Front", "").strip()
            back = card.get("Back", "").strip()
            if not front or not back:
                continue

            note = col.new_note(model)
            note["Front"] = front
            note["Back"] = back
            col.add_note(note, deck_id)
            added += 1

        return added


# -----------------------------------------------------------------------------
# Menu registration
# -----------------------------------------------------------------------------

def _launch_dialog():
    NotebookLMDialog(mw).exec()


action = QAction(ADDON_MENU_TEXT, mw)
action.triggered.connect(_launch_dialog)
mw.form.menuTools.addAction(action)
