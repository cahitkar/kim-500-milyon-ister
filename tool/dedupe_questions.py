#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import re
import os

def parse_questions(file_path):
    """Veri dosyasından soruları parse eder"""
    questions = []
    current_question = None
    current_options = []
    current_answer = None
    current_level = None
    
    with open(file_path, 'r', encoding='utf-8') as f:
        lines = f.readlines()
    
    for line in lines:
        line = line.strip()
        if not line:
            continue
            
        # Seviye başlığını kontrol et
        if line.startswith('=== SEVİYE'):
            current_level = line
            continue
            
        # Soru satırını kontrol et (soru işareti ile biten)
        if line.endswith('?'):
            # Önceki soruyu kaydet
            if current_question:
                questions.append({
                    'level': current_level,
                    'question': current_question,
                    'options': current_options,
                    'answer': current_answer
                })
            
            # Yeni soru başlat
            current_question = line
            current_options = []
            current_answer = None
            continue
            
        # Seçenek satırını kontrol et (sayı ile başlayan)
        if re.match(r'^\d+\)', line):
            current_options.append(line)
            continue
            
        # Doğru cevap satırını kontrol et
        if line.startswith('Doğru Cevap:'):
            current_answer = line.replace('Doğru Cevap:', '').strip()
            continue
    
    # Son soruyu da ekle
    if current_question:
        questions.append({
            'level': current_level,
            'question': current_question,
            'options': current_options,
            'answer': current_answer
        })
    
    return questions

def find_duplicates(questions):
    """Tekrar olan soruları bulur"""
    seen_questions = {}
    duplicates = []
    
    for i, q in enumerate(questions):
        # Soru metnini normalize et (büyük/küçük harf farkını göz ardı et)
        normalized_question = q['question'].lower().strip()
        
        if normalized_question in seen_questions:
            duplicates.append({
                'index': i,
                'question': q,
                'duplicate_of': seen_questions[normalized_question]
            })
        else:
            seen_questions[normalized_question] = i
    
    return duplicates

def remove_duplicates(questions):
    """Tekrar olan soruları kaldırır"""
    seen_questions = set()
    unique_questions = []
    
    for q in questions:
        normalized_question = q['question'].lower().strip()
        
        if normalized_question not in seen_questions:
            seen_questions.add(normalized_question)
            unique_questions.append(q)
    
    return unique_questions

def write_clean_file(questions, output_path):
    """Temizlenmiş soruları dosyaya yazar"""
    with open(output_path, 'w', encoding='utf-8') as f:
        current_level = None
        
        for q in questions:
            # Seviye değiştiğinde başlık yaz
            if q['level'] != current_level:
                f.write(f"{q['level']}\n")
                current_level = q['level']
            
            # Soruyu yaz
            f.write(f"{q['question']}\n")
            
            # Seçenekleri yaz
            for option in q['options']:
                f.write(f"{option}\n")
            
            # Doğru cevabı yaz
            f.write(f"Doğru Cevap: {q['answer']}\n\n")

def main():
    # Veri dosyalarını kontrol et
    data_dir = "assets/data"
    files = ["veri.txt", "veri_backup.txt", "veri_backup_lvlmove.txt"]
    
    all_questions = []
    
    for file_name in files:
        file_path = os.path.join(data_dir, file_name)
        if os.path.exists(file_path):
            print(f"📖 {file_name} dosyası okunuyor...")
            questions = parse_questions(file_path)
            all_questions.extend(questions)
            print(f"   {len(questions)} soru bulundu")
    
    print(f"\n📊 Toplam soru sayısı: {len(all_questions)}")
    
    # Tekrar olan soruları bul
    duplicates = find_duplicates(all_questions)
    print(f"🔄 Tekrar olan soru sayısı: {len(duplicates)}")
    
    if duplicates:
        print("\n📋 Tekrar olan sorular:")
        for dup in duplicates[:10]:  # İlk 10 tekrarı göster
            print(f"   - {dup['question']['question']}")
        if len(duplicates) > 10:
            print(f"   ... ve {len(duplicates) - 10} soru daha")
    
    # Tekrarları kaldır
    unique_questions = remove_duplicates(all_questions)
    print(f"\n✨ Tekrarlar kaldırıldıktan sonra: {len(unique_questions)} soru")
    
    # Seviye bazında dağılım
    level_counts = {}
    for q in unique_questions:
        level = q['level']
        level_counts[level] = level_counts.get(level, 0) + 1
    
    print("\n📈 Seviye bazında soru dağılımı:")
    for level in sorted(level_counts.keys()):
        print(f"   {level}: {level_counts[level]} soru")
    
    # Temizlenmiş dosyayı oluştur
    output_path = os.path.join(data_dir, "veri_temiz.txt")
    write_clean_file(unique_questions, output_path)
    print(f"\n💾 Temizlenmiş dosya oluşturuldu: {output_path}")
    
    return len(all_questions), len(duplicates), len(unique_questions)

if __name__ == "__main__":
    total, duplicates, unique = main()
    print(f"\n🎯 Özet:")
    print(f"   Toplam soru: {total}")
    print(f"   Tekrar olan: {duplicates}")
    print(f"   Benzersiz: {unique}")
