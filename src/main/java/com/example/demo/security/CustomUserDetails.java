package com.example.demo.security;

import com.example.demo.dto.MemberDto;
import lombok.EqualsAndHashCode;
import lombok.Getter;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.userdetails.UserDetails;

import java.util.Collection;
import java.util.List;

@Getter
@EqualsAndHashCode(of = "memberDto.memberId")
public class CustomUserDetails implements UserDetails {

    // 로그인한 회원 정보를 보관
    private final MemberDto memberDto;

    public CustomUserDetails(MemberDto memberDto) {
        this.memberDto = memberDto;
    }

    // 회원 권한 반환
    @Override
    public Collection<? extends SimpleGrantedAuthority> getAuthorities() {
        return List.of(new SimpleGrantedAuthority("ROLE_USER"));
    }

    @Override
    public String getPassword() {
        return memberDto.getMemberPassword();
    }

    @Override
    public String getUsername() {
        return memberDto.getMemberId();
    }

    // 계정 만료 여부 (true: 만료 안 됨) - [추가된 필수 메서드]
    @Override
    public boolean isAccountNonExpired() {
        return true;
    }

    // 계정 잠금 여부 (DORMANT, DELETED 상태면 잠김 처리 -> LockedException 발생)
    @Override
    public boolean isAccountNonLocked() {
        String status = memberDto.getMemberStatus();
        return !"DORMANT".equals(status) && !"DELETED".equals(status);
    }

    // 비밀번호 만료 여부 (true: 만료 안 됨) - [에러 원인 / 추가된 필수 메서드]
    @Override
    public boolean isCredentialsNonExpired() {
        return true;
    }

    // 활성화 여부 (BANNED 상태면 비활성화)
    @Override
    public boolean isEnabled() {
        return !"BANNED".equals(memberDto.getMemberStatus());
    }
}