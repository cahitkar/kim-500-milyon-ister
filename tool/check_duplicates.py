#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import re

def check_duplicates():
    """veri.txt dosyasında tekrar eden soruları tespit eder"""
    
    with open('assets/data/veri.txt', 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Soruları ayır
    questions = []
    lines = content.split('\n')
    
    current_question = None
    current_options = []
    current_answer = None
    current_level = None
    
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
                    'question': current_question,
                    'options': current_options.copy(),
                    'answer': current_answer,
                    'level': current_level
                })
            
            # Yeni soru başlat
            current_question = line
            current_options = []
            current_answer = None
            continue
            
        # Seçenek satırını kontrol et
        if line.startswith(('1)', '2)', '3)', '4)')):
            current_options.append(line)
            continue
            
        # Doğru cevap satırını kontrol et
        if line.startswith('Doğru Cevap:'):
            current_answer = line
            continue
    
    # Son soruyu da ekle
    if current_question:
        questions.append({
            'question': current_question,
            'options': current_options.copy(),
            'answer': current_answer,
            'level': current_level
        })
    
    # Tekrar eden soruları bul
    question_texts = []
    duplicates = []
    
    for i, q in enumerate(questions):
        if q['question'] in question_texts:
            # Tekrar bulundu
            first_index = question_texts.index(q['question'])
            duplicates.append({
                'first': questions[first_index],
                'duplicate': q,
                'first_index': first_index,
                'duplicate_index': i
            })
        else:
            question_texts.append(q['question'])
    
    # Sonuçları yazdır
    print(f"Toplam soru sayısı: {len(questions)}")
    print(f"Tekrar eden soru sayısı: {len(duplicates)}")
    
    if duplicates:
        print("\nTekrar eden sorular:")
        for i, dup in enumerate(duplicates, 1):
            print(f"\n{i}. Tekrar:")
            print(f"   İlk: {dup['first']['question']} ({dup['first']['level']})")
            print(f"   Tekrar: {dup['duplicate']['question']} ({dup['duplicate']['level']})")
    else:
        print("\nTekrar eden soru bulunamadı!")
    
    return duplicates

if __name__ == "__main__":
    check_duplicates()
