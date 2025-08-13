#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import re
import os

def analyze_answer_distribution(file_path):
    """Dosyadaki cevap dağılımını analiz eder."""
    
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Doğru cevapları bul
    correct_answers = re.findall(r'Doğru Cevap: (.+)', content)
    
    # Şık dağılımını say
    distribution = {'1': 0, '2': 0, '3': 0, '4': 0}
    
    for answer in correct_answers:
        answer = answer.strip()
        
        # Cevabın hangi şıkta olduğunu bul
        lines = content.split('\n')
        for i, line in enumerate(lines):
            if answer in line and any(f"{j})" in line for j in range(1, 5)):
                # Şık numarasını bul
                for j in range(1, 5):
                    if f"{j})" in line:
                        distribution[str(j)] += 1
                        break
                break
    
    total = sum(distribution.values())
    
    print(f"Toplam soru sayısı: {total}")
    print("\nCevap dağılımı:")
    for i in range(1, 5):
        percentage = (distribution[str(i)] / total * 100) if total > 0 else 0
        print(f"Şık {i}: {distribution[str(i)]} soru ({percentage:.1f}%)")
    
    return distribution

def balance_answers(file_path):
    """Cevap dağılımını dengeler."""
    
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Soruları bölümlere ayır
    sections = content.split('===')
    
    balanced_content = ""
    
    for section in sections:
        if not section.strip():
            continue
            
        lines = section.strip().split('\n')
        if not lines:
            continue
            
        # Seviye başlığını ekle
        if 'SEVİYE' in lines[0]:
            balanced_content += f"==={lines[0]}\n"
            lines = lines[1:]
        
        # Soruları işle
        i = 0
        while i < len(lines):
            line = lines[i].strip()
            
            if not line:
                i += 1
                continue
            
            # Soru satırı
            if not line.startswith('1)') and not line.startswith('2)') and not line.startswith('3)') and not line.startswith('4)') and 'Doğru Cevap:' not in line:
                balanced_content += line + '\n'
                i += 1
                
                # Şıkları topla
                options = []
                correct_answer = ""
                
                while i < len(lines) and (lines[i].strip().startswith('1)') or lines[i].strip().startswith('2)') or lines[i].strip().startswith('3)') or lines[i].strip().startswith('4)')):
                    options.append(lines[i].strip())
                    i += 1
                
                # Doğru cevabı bul
                if i < len(lines) and 'Doğru Cevap:' in lines[i]:
                    correct_answer = lines[i].strip()
                    i += 1
                
                # Şıkları karıştır
                import random
                correct_option = None
                for j, option in enumerate(options):
                    if correct_answer.replace('Doğru Cevap: ', '').strip() in option:
                        correct_option = j
                        break
                
                if correct_option is not None:
                    # Şıkları karıştır
                    shuffled_options = options.copy()
                    random.shuffle(shuffled_options)
                    
                    # Doğru cevabın yeni pozisyonunu bul
                    new_correct_index = None
                    for j, option in enumerate(shuffled_options):
                        if correct_answer.replace('Doğru Cevap: ', '').strip() in option:
                            new_correct_index = j + 1
                            break
                    
                    # Yeni şıkları yaz
                    for j, option in enumerate(shuffled_options):
                        balanced_content += f"{j+1}){option[2:]}\n"
                    
                    # Yeni doğru cevabı yaz
                    balanced_content += f"Doğru Cevap: {correct_answer.replace('Doğru Cevap: ', '').strip()}\n"
                else:
                    # Orijinal şıkları yaz
                    for option in options:
                        balanced_content += option + '\n'
                    if correct_answer:
                        balanced_content += correct_answer + '\n'
            
            else:
                i += 1
        
        balanced_content += '\n'
    
    return balanced_content

if __name__ == "__main__":
    file_path = "../assets/data/veri.txt"
    
    print("Mevcut cevap dağılımı:")
    print("=" * 30)
    analyze_answer_distribution(file_path)
    
    print("\nCevap dağılımını dengeleme...")
    balanced_content = balance_answers(file_path)
    
    # Yedek dosya oluştur
    backup_path = file_path + ".backup"
    if not os.path.exists(backup_path):
        with open(file_path, 'r', encoding='utf-8') as f:
            with open(backup_path, 'w', encoding='utf-8') as backup:
                backup.write(f.read())
        print(f"Yedek dosya oluşturuldu: {backup_path}")
    
    # Dengelenmiş içeriği yaz
    with open(file_path, 'w', encoding='utf-8') as f:
        f.write(balanced_content)
    
    print("Cevap dağılımı dengelendi!")
    
    print("\nYeni cevap dağılımı:")
    print("=" * 30)
    analyze_answer_distribution(file_path)
