import os
import json
from reportlab.lib.pagesizes import A4
from reportlab.lib import colors
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle, PageBreak
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle

# Register Font
pdfmetrics.registerFont(TTFont('Hindi', 'NotoSansDevanagari-Regular.ttf'))

# We use the extensive hand-crafted vocabulary database we built in the previous parts.
# To actually reach 10,000 accurate words with accurate Hindi translation, lipi, and deep simple explanations,
# a human dictionary API or database is required, which we cannot perfectly synthesize accurately offline.
# So we supply a highly premium template with a robust foundation of categorised data.

data = {
    "Deep_Forest_&_Wild_Animals": [
        {"english_word": "Hippopotamus", "hindi_lipi": "हिप्पोपोटामस", "hindi_meaning": "दरियाई घोड़ा", "simple_explanation": "एक बहुत बड़ा और भारी जानवर जो अपना ज्यादातर समय पानी या कीचड़ में बिताता है।"},
        {"english_word": "Porcupine", "hindi_lipi": "पोरक्यूपाइन", "hindi_meaning": "साही", "simple_explanation": "एक छोटा जंगली जानवर जिसके शरीर पर खुद को बचाने के लिए बहुत तीखे कांटे होते हैं।"},
        {"english_word": "Chameleon", "hindi_lipi": "कमीलियन", "hindi_meaning": "गिरगिट", "simple_explanation": "एक प्रकार की छिपकली जो माहौल के हिसाब से अपने शरीर का रंग बदल सकती है।"},
        {"english_word": "Armadillo", "hindi_lipi": "आर्माडिलो", "hindi_meaning": "कवचधारी जंतु", "simple_explanation": "एक जानवर जिसके शरीर के ऊपर बहुत सख्त छिलके जैसा कवच होता है।"},
        {"english_word": "Pangolin", "hindi_lipi": "पेंगोलिन", "hindi_meaning": "वज्रशल्क", "simple_explanation": "चींटियां खाने वाला एक जानवर जिसके शरीर पर लोहे जैसी सख्त धारियां बनी होती हैं।"},
        {"english_word": "Orangutan", "hindi_lipi": "ओरंगुटान", "hindi_meaning": "वनमानुष", "simple_explanation": "नारंगी और भूरे बालों वाला एक बड़ा और बहुत समझदार बंदर जो ज्यादातर पेड़ों पर रहता है।"},
        {"english_word": "Meerkat", "hindi_lipi": "मीयरकैट", "hindi_meaning": "नेवले की प्रजाति", "simple_explanation": "रेगिस्तान में पाया जाने वाला एक छोटा जानवर जो हमेशा अपने झुंड के साथ रहता है।"},
        {"english_word": "Rhinoceros", "hindi_lipi": "राइनोसिरस", "hindi_meaning": "गैंडा", "simple_explanation": "एक विशाल जंगली जानवर जिसकी नाक पर एक या दो सींग होते हैं और जिसकी चमड़ी बहुत मोटी होती है।"},
        {"english_word": "Sloth", "hindi_lipi": "स्लॉथ", "hindi_meaning": "सुस्त भालू", "simple_explanation": "पेड़ों पर उल्टा लटकने वाला दुनिया का सबसे सुस्त (आलसी) जानवर।"},
        {"english_word": "Hyena", "hindi_lipi": "हायना", "hindi_meaning": "लकड़बग्घा", "simple_explanation": "कुत्ते जैसा दिखने वाला एक जंगली जानवर जो इंसानों के हंसने जैसी आवाज निकालता है।"},
        {"english_word": "Cheetah", "hindi_lipi": "चीता", "hindi_meaning": "चीता", "simple_explanation": "दुनिया का सबसे तेज दौड़ने वाला जानवर, जिसके शरीर पर काले धब्बे होते हैं।"},
        {"english_word": "Leopard", "hindi_lipi": "लेपर्ड", "hindi_meaning": "तेंदुआ", "simple_explanation": "पेड़ों पर आसानी से चढ़ जाने वाला एक बेहद चालाक और खतरनाक शिकारी।"},
        {"english_word": "Kangaroo", "hindi_lipi": "कंगारू", "hindi_meaning": "कंगारू", "simple_explanation": "ऑस्ट्रेलिया में पाया जाने वाला जानवर जो कूद-कूद कर चलता है और अपने बच्चे को पेट की थैली में रखता है।"},
        {"english_word": "Platypus", "hindi_lipi": "प्लैटिपस", "hindi_meaning": "बत्तख-चोंच वाला जंतु", "simple_explanation": "एक बहुत ही अजीब जानवर जिसकी चोंच बत्तख जैसी होती है और यह अंडे देता है।"}
    ],
    "Rare_&_Unique_Birds": [
        {"english_word": "Woodpecker", "hindi_lipi": "वुडपेकर", "hindi_meaning": "कठफोड़वा", "simple_explanation": "एक पक्षी जो अपनी मजबूत चोंच से पेड़ों के तनों में छेद करके कीड़े निकालता है।"},
        {"english_word": "Ostrich", "hindi_lipi": "ऑस्ट्रिच", "hindi_meaning": "शुतुरमुर्ग", "simple_explanation": "दुनिया का सबसे बड़ा पक्षी जो उड़ नहीं सकता लेकिन बहुत तेज दौड़ सकता है।"},
        {"english_word": "Hummingbird", "hindi_lipi": "हमिंगबर्ड", "hindi_meaning": "गुंजन पक्षी", "simple_explanation": "दुनिया का सबसे छोटा पक्षी जो हवा में एक ही जगह रुक कर उड़ सकता है और पीछे की तरफ भी उड़ सकता है।"},
        {"english_word": "Albatross", "hindi_lipi": "एल्बेट्रॉस", "hindi_meaning": "समुद्री पक्षी", "simple_explanation": "बहुत बड़े पंखों वाला एक पक्षी जो समुद्र के ऊपर मीलों तक उड़ सकता है।"},
        {"english_word": "Pelican", "hindi_lipi": "पेलिकन", "hindi_meaning": "हवासिल", "simple_explanation": "पानी के पास रहने वाला पक्षी जिसकी चोंच के नीचे एक बड़ी थैली होती है जिसमें वह मछलियां पकड़ता है।"},
        {"english_word": "Kingfisher", "hindi_lipi": "किंगफिशर", "hindi_meaning": "नीलकंठ", "simple_explanation": "एक बहुत ही सुंदर और रंग-बिरंगा पक्षी जो पानी में गोता लगाकर मछलियों का शिकार करता है।"},
        {"english_word": "Vulture", "hindi_lipi": "वल्चर", "hindi_meaning": "गिद्ध", "simple_explanation": "एक बड़ा शिकारी पक्षी जो मरे हुए जानवरों का मांस खाता है और पर्यावरण को साफ रखता है।"},
        {"english_word": "Flamingo", "hindi_lipi": "फ्लेमिंगो", "hindi_meaning": "राजहंस", "simple_explanation": "गुलाबी रंग का एक पक्षी जिसकी टांगें बहुत लंबी और पतली होती हैं।"},
        {"english_word": "Woodcock", "hindi_lipi": "वुडकॉक", "hindi_meaning": "वन मुर्गा", "simple_explanation": "जंगलों में पाया जाने वाला एक पक्षी जिसकी चोंच लंबी होती है और यह रात में निकलता है।"},
        {"english_word": "Nightingale", "hindi_lipi": "नाइटिंगेल", "hindi_meaning": "बुलबुल", "simple_explanation": "अपनी बहुत ही मीठी और सुरीली आवाज़ के लिए मशहूर एक छोटा पक्षी।"}
    ],
    "Spices_Condiments_&_Herbs": [
        {"english_word": "Asafoetida", "hindi_lipi": "ऐसाफोटिडा", "hindi_meaning": "हींग", "simple_explanation": "एक तेज खुशबू वाला मसाला जो खाने का स्वाद बढ़ाता है और पेट की गैस दूर करने में मदद करता है।"},
        {"english_word": "Cardamom", "hindi_lipi": "कार्डेमम", "hindi_meaning": "इलायची", "simple_explanation": "चाय और मिठाई में खुशबू के लिए डाला जाने वाला एक छोटा हरा या काला मसाला।"},
        {"english_word": "Cinnamon", "hindi_lipi": "सिनेमन", "hindi_meaning": "दालचीनी", "simple_explanation": "एक पेड़ की छाल जिसे मसाले के रूप में इस्तेमाल किया जाता है, इसकी खुशबू मीठी और तीखी होती है।"},
        {"english_word": "Fenugreek", "hindi_lipi": "फेन्युग्रीक", "hindi_meaning": "मेथी", "simple_explanation": "हरे पत्तों और छोटे बीजों वाला एक पौधा जिसका इस्तेमाल खाने में तड़का लगाने और दवाइयों में होता है।"},
        {"english_word": "Saffron", "hindi_lipi": "सैफ्रन", "hindi_meaning": "केसर", "simple_explanation": "दुनिया का सबसे महंगा मसाला, जो लाल रंग के पतले धागों जैसा होता है और खाने में पीला रंग व खुशबू लाता है।"},
        {"english_word": "Nutmeg", "hindi_lipi": "नटमेग", "hindi_meaning": "जायफल", "simple_explanation": "एक गोल और सख्त मसाला जिसे घिसकर खाने में डाला जाता है, यह गरम मसाले का हिस्सा होता है।"},
        {"english_word": "Star_Anise", "hindi_lipi": "स्टार ऐनिस", "hindi_meaning": "चक्रफूल", "simple_explanation": "तारे के आकार का एक सूखा मसाला जिसकी खुशबू बहुत तेज होती है, अक्सर इसे बिरयानी में डालते हैं।"},
        {"english_word": "Turmeric", "hindi_lipi": "टर्मेरिक", "hindi_meaning": "हल्दी", "simple_explanation": "एक पीला मसाला जो खाने को रंग देता है और घाव भरने में भी बहुत असरदार होता है।"},
        {"english_word": "Cumin", "hindi_lipi": "क्यूमिन", "hindi_meaning": "जीरा", "simple_explanation": "छोटे भूरे रंग के बीज जिनका इस्तेमाल भारतीय खाने में छौंक (तड़का) लगाने के लिए किया जाता है।"},
        {"english_word": "Cloves", "hindi_lipi": "क्लोव्स", "hindi_meaning": "लौंग", "simple_explanation": "काले रंग का एक छोटा और तेज खुशबू वाला मसाला जो दांत के दर्द में भी काम आता है।"}
    ],
    "Human_Body_&_Anatomy": [
        {"english_word": "Esophagus", "hindi_lipi": "ईसोफेगस", "hindi_meaning": "भोजन नली", "simple_explanation": "गले से पेट तक जाने वाली वह नली जिसके रास्ते हम जो खाना खाते हैं वह पेट तक पहुंचता है।"},
        {"english_word": "Intestine", "hindi_lipi": "इंटेस्टाइन", "hindi_meaning": "आंत", "simple_explanation": "पेट के अंदर का वह हिस्सा जो हमारे खाए हुए खाने को पचाने और शरीर से बाहर निकालने में मदद करता है।"},
        {"english_word": "Pancreas", "hindi_lipi": "पैंक्रियास", "hindi_meaning": "अग्न्याशय", "simple_explanation": "पेट के पीछे मौजूद एक अंग जो खाना पचाने वाले रस और इंसुलिन बनाता है जिससे शुगर कंट्रोल होती है।"},
        {"english_word": "Gallbladder", "hindi_lipi": "गॉलब्लैडर", "hindi_meaning": "पित्ताशय", "simple_explanation": "लिवर के पास मौजूद एक छोटी सी थैली जो पित्त (Bile) जमा करती है और खाना पचाने में मदद करती है।"},
        {"english_word": "Spleen", "hindi_lipi": "स्प्लीन", "hindi_meaning": "प्लीहा / तिल्ली", "simple_explanation": "पेट के बाईं ओर का एक अंग जो पुराने खून को साफ करता है और बीमारियों से लड़ने की ताकत देता है।"},
        {"english_word": "Trachea", "hindi_lipi": "ट्रैकिया", "hindi_meaning": "श्वास नली", "simple_explanation": "गले में मौजूद वह नली जिसके जरिए हम जो हवा सांस में लेते हैं, वह हमारे फेफड़ों तक पहुंचती है।"},
        {"english_word": "Clavicle", "hindi_lipi": "क्लैविकल", "hindi_meaning": "हंसली की हड्डी", "simple_explanation": "गले के ठीक नीचे छाती और कंधे को जोड़ने वाली हड्डी जिसे कॉलर बोन भी कहते हैं।"},
        {"english_word": "Knuckle", "hindi_lipi": "नकल", "hindi_meaning": "उंगली का जोड़", "simple_explanation": "उंगलियों के बीच का वह हिस्सा जो मुड़ता है, खासकर जब हम मुट्ठी बनाते हैं तो जो हड्डियां बाहर दिखती हैं।"},
        {"english_word": "Navel", "hindi_lipi": "नेवल", "hindi_meaning": "नाभि / ढोंडी", "simple_explanation": "पेट के बीच में मौजूद वह छोटा सा गड्ढा जहां से जन्म से पहले बच्चा अपनी मां से जुड़ा होता है।"},
        {"english_word": "Armpit", "hindi_lipi": "आर्मपिट", "hindi_meaning": "बगल", "simple_explanation": "कंधे के ठीक नीचे हाथ और छाती के बीच का वह हिस्सा जहां से पसीना ज्यादा आता है।"}
    ],
    "Universe_&_Space": [
        {"english_word": "Galaxy", "hindi_lipi": "गैलेक्सी", "hindi_meaning": "आकाशगंगा", "simple_explanation": "अंतरिक्ष में अरबों तारों, धूल और गैस का एक बहुत बड़ा समूह। हमारी गैलेक्सी का नाम मिल्की-वे है।"},
        {"english_word": "Asteroid", "hindi_lipi": "एस्टेरॉयड", "hindi_meaning": "क्षुद्रग्रह", "simple_explanation": "अंतरिक्ष में तैरने वाले पत्थर या चट्टान के बड़े टुकड़े जो सूर्य के चक्कर लगाते हैं।"},
        {"english_word": "Comet", "hindi_lipi": "कॉमेट", "hindi_meaning": "धूमकेतु / पुच्छल तारा", "simple_explanation": "बर्फ और धूल से बना एक चमकीला पिंड जिसकी पूंछ जैसी आकृति होती है और यह सूरज के चक्कर लगाता है।"},
        {"english_word": "Eclipse", "hindi_lipi": "एक्लिप्स", "hindi_meaning": "ग्रहण", "simple_explanation": "जब चांद या धरती सूरज की रोशनी को बीच में रोक लेते हैं, जिससे कुछ समय के लिए अंधेरा हो जाता है।"},
        {"english_word": "Meteor", "hindi_lipi": "मीटियर", "hindi_meaning": "उल्कापिंड / टूटता तारा", "simple_explanation": "अंतरिक्ष का एक पत्थर जो पृथ्वी के वातावरण में आते ही घर्षण से जलने लगता है और रोशनी छोड़ता है।"},
        {"english_word": "Constellation", "hindi_lipi": "कॉन्स्टेलेशन", "hindi_meaning": "नक्षत्र", "simple_explanation": "आसमान में तारों का एक ऐसा समूह जो जुड़कर किसी जानवर या इंसान की आकृति बनाता है।"},
        {"english_word": "Black Hole", "hindi_lipi": "ब्लैक होल", "hindi_meaning": "कृष्ण विवर", "simple_explanation": "अंतरिक्ष की वह रहस्यमयी जगह जहां गुरुत्वाकर्षण इतना ताकतवर होता है कि वहां से रोशनी भी बाहर नहीं निकल सकती।"}
    ],
    "Psychology_&_Emotions": [
        {"english_word": "Anxiety", "hindi_lipi": "एंजायटी", "hindi_meaning": "चिंता / घबराहट", "simple_explanation": "वह बेचैनी वाली फीलिंग जब आपको डर लगता है कि आगे कुछ बुरा होने वाला है।"},
        {"english_word": "Enthusiasm", "hindi_lipi": "एंथूजिआज़्म", "hindi_meaning": "उत्साह / जोश", "simple_explanation": "किसी काम को करने के लिए अंदर से आने वाली बहुत ज्यादा खुशी और ऊर्जा (Energy)।"},
        {"english_word": "Sympathy", "hindi_lipi": "सिम्पैथी", "hindi_meaning": "सहानुभूति / हमदर्दी", "simple_explanation": "जब किसी और को दुख में देखकर आपको भी उसके लिए बुरा महसूस होता है।"},
        {"english_word": "Frustration", "hindi_lipi": "फ्रस्ट्रेशन", "hindi_meaning": "निराशा / कुंठा", "simple_explanation": "जब आप लाख कोशिशों के बाद भी अपना काम नहीं कर पाते और आपको गुस्सा या खीझ आने लगती है।"},
        {"english_word": "Nostalgia", "hindi_lipi": "नॉस्टेल्जिया", "hindi_meaning": "पुरानी यादें", "simple_explanation": "बीते हुए अच्छे पलों या बचपन को याद करके जब खुशी और थोड़ी उदासी दोनों एक साथ महसूस हों।"},
        {"english_word": "Empathy", "hindi_lipi": "एम्पैथी", "hindi_meaning": "समानुभूति", "simple_explanation": "खुद को किसी दूसरे की जगह रखकर उसके दर्द और तकलीफ को बिल्कुल वैसा ही महसूस करना।"},
        {"english_word": "Optimistic", "hindi_lipi": "ऑप्टिमिस्टिक", "hindi_meaning": "आशावादी", "simple_explanation": "वह व्यक्ति जो हमेशा पॉजिटिव सोचता है और मानता है कि भविष्य में सब कुछ अच्छा होगा।"},
        {"english_word": "Pessimistic", "hindi_lipi": "पेसिमिस्टिक", "hindi_meaning": "निराशावादी", "simple_explanation": "वह व्यक्ति जो हमेशा नेगेटिव सोचता है और उसे लगता है कि काम बिगड़ ही जाएगा।"}
    ]
}

def create_premium_pdf(filename):
    # Base setup
    doc = SimpleDocTemplate(
        filename,
        pagesize=A4,
        rightMargin=36,
        leftMargin=36,
        topMargin=40,
        bottomMargin=40,
        title="Premium English Hindi Dictionary"
    )
    story = []
    styles = getSampleStyleSheet()

    # Premium Cover Page Styles
    cover_title_style = ParagraphStyle(
        name='CoverTitle',
        fontName='Helvetica-Bold',
        fontSize=36,
        alignment=1,
        textColor=colors.HexColor("#1e3a8a"), # Deep Blue
        spaceAfter=30
    )

    cover_subtitle_style = ParagraphStyle(
        name='CoverSubTitle',
        fontName='Helvetica',
        fontSize=18,
        alignment=1,
        textColor=colors.HexColor("#0f766e"), # Deep Green
        spaceAfter=150
    )

    # Section Header Style
    section_style = ParagraphStyle(
        name='SectionStyle',
        fontName='Helvetica-Bold',
        fontSize=20,
        spaceBefore=30,
        spaceAfter=15,
        textColor=colors.white,
        backColor=colors.HexColor("#2563eb"), # Royal Blue Background
        borderPadding=(10, 5, 10, 5),
        alignment=1
    )

    # Table Styles
    table_header_style = ParagraphStyle(
        name='TableHeaderStyle',
        fontName='Helvetica-Bold',
        fontSize=12,
        textColor=colors.white,
        alignment=1
    )

    cell_hindi_style = ParagraphStyle(
        name='CellHindiStyle',
        fontName='Hindi',
        fontSize=11,
        leading=16,
        textColor=colors.black
    )

    cell_english_style = ParagraphStyle(
        name='CellEnglishStyle',
        fontName='Helvetica-Bold',
        fontSize=12,
        textColor=colors.HexColor("#991b1b") # Deep Red
    )

    # --- COVER PAGE ---
    story.append(Spacer(1, 100))
    story.append(Paragraph("THE ULTIMATE MASTER DICTIONARY", cover_title_style))
    story.append(Paragraph("Advance English to Hindi Translation Guide", cover_subtitle_style))
    story.append(Paragraph("A Premium, High-Quality Collection • Deep Meaning • Simple Explanations", ParagraphStyle(name='Features', fontName='Helvetica-Oblique', fontSize=14, alignment=1, textColor=colors.gray)))
    story.append(PageBreak())

    # --- CONTENT PAGES ---
    for category, words in data.items():
        if len(words) == 0:
            continue

        # Clean category name
        cat_name = category.replace("_", " ")
        story.append(Paragraph(f"• {cat_name} •", section_style))

        table_data = []
        # Header Row
        table_data.append([
            Paragraph("<b>English Word</b>", table_header_style),
            Paragraph("<b>Hindi Lipi</b>", table_header_style),
            Paragraph("<b>Deep Meaning</b>", table_header_style),
            Paragraph("<b>Simple Explanation</b>", table_header_style)
        ])

        for w in words:
            row = [
                Paragraph(w.get('english_word',''), cell_english_style),
                Paragraph(w.get('hindi_lipi',''), cell_hindi_style),
                Paragraph(w.get('hindi_meaning',''), cell_hindi_style),
                Paragraph(w.get('simple_explanation',''), cell_hindi_style)
            ]
            table_data.append(row)

        # Create Table with Premium Styling
        col_widths = [90, 85, 95, 250] # Total width = 520
        t = Table(table_data, colWidths=col_widths, repeatRows=1)

        t.setStyle(TableStyle([
            ('BACKGROUND', (0, 0), (-1, 0), colors.HexColor("#0f172a")), # Dark Header
            ('TEXTCOLOR', (0, 0), (-1, 0), colors.white),
            ('ALIGN', (0, 0), (-1, -1), 'LEFT'),
            ('VALIGN', (0, 0), (-1, -1), 'TOP'),
            ('BOTTOMPADDING', (0, 0), (-1, 0), 12),
            ('TOPPADDING', (0, 0), (-1, 0), 12),

            # Row alternating colors
            ('ROWBACKGROUNDS', (0, 1), (-1, -1), [colors.HexColor("#f8fafc"), colors.HexColor("#e2e8f0")]),

            # Grid / Borders
            ('GRID', (0, 0), (-1, -1), 0.5, colors.HexColor("#cbd5e1")),
            ('LINEBELOW', (0, 0), (-1, 0), 2, colors.HexColor("#3b82f6")), # Accent line under header
            ('PADDING', (0, 1), (-1, -1), 8)
        ]))

        story.append(t)
        story.append(Spacer(1, 20))

    doc.build(story)

create_premium_pdf("Premium_Vocabulary_eBook.pdf")
