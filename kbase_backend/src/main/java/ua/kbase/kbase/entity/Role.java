package ua.kbase.kbase.entity;

import jakarta.persistence.*;
import lombok.*;
import java.time.LocalDateTime;
import java.util.HashSet;
import java.util.Set;

@Entity
@Table(name = "roles")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Role {

    @Id
    @GeneratedValue(strategy = GenerationType.SEQUENCE, generator = "seq_roles_gen")
    @SequenceGenerator(name = "seq_roles_gen", sequenceName = "seq_roles", allocationSize = 1)
    private Long id;

    @Column(nullable = false, unique = true, length = 50)
    private String name;

    @Column(length = 200)
    private String descr;

    @ManyToMany(fetch = FetchType.EAGER)
    @JoinTable(
        name = "role_privileges",
        joinColumns = @JoinColumn(name = "role_id"),
        inverseJoinColumns = @JoinColumn(name = "privilege_id")
    )
    @Builder.Default
    private Set<Privilege> privileges = new HashSet<>();

    @Column(name = "date_created")
    private LocalDateTime dateCreated;

    @Column(name = "date_modified")
    private LocalDateTime dateModified;

    @Column(name = "user_created", length = 30)
    private String userCreated;

    @Column(name = "user_modified", length = 30)
    private String userModified;

    @PrePersist
    protected void onCreate() {
        if (dateCreated == null) {
            dateCreated = LocalDateTime.now();
        }
        if (dateModified == null) {
            dateModified = LocalDateTime.now();
        }
    }

    @PreUpdate
    protected void onUpdate() {
        dateModified = LocalDateTime.now();
    }
}
